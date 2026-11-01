#!/usr/bin/env bash
# Phone the user through Bland.ai, wait for the call to end, print the result as JSON.
#
#   call-me.sh ask "<question>" ["<background to share only if asked>"]
#   call-me.sh wait <call_id>      # resume polling an existing call; never places a new one
#
# Reads BLAND_API_KEY and CALL_ME_PHONE (E.164) from the environment, falling back to the
# macOS keychain. Optional: CALL_ME_VOICE, CALL_ME_FROM, CALL_ME_TIMEOUT (seconds, default 540),
# BLAND_TWILIO_KEY (Bland's encrypted_key for the user's own Twilio account).
# The key is passed to curl on stdin, never on the command line.
set -euo pipefail

API=https://api.bland.ai/v1

secret() {
  local name=$1
  if [ -n "${!name:-}" ]; then printf '%s' "${!name}"; return; fi
  if command -v security >/dev/null 2>&1; then
    security find-generic-password -s "$name" -w 2>/dev/null && return
  fi
  echo "call-me: $name is not set (environment or keychain)" >&2
  exit 2
}

KEY=$(secret BLAND_API_KEY)

bland() { # bland METHOD PATH [JSON_BODY]
  local method=$1 path=$2 body=${3:-}
  local args=(-sS -X "$method" -K - "$API$path")
  [ -n "$body" ] && args+=(-H 'content-type: application/json' --data-binary "$body")
  local cfg="header = \"authorization: $KEY\""
  # Calling from the user's own Twilio account (needed for countries Bland's numbers can't reach).
  [ -n "${BLAND_TWILIO_KEY:-}" ] && cfg+=$'\n'"header = \"encrypted_key: $BLAND_TWILIO_KEY\""
  curl "${args[@]}" <<<"$cfg"
}

place_call() {
  local question=$1 background=${2:-none}
  local phone task body resp
  phone=$(secret CALL_ME_PHONE)
  task=$(cat <<EOF
You are an assistant calling on behalf of the user's AI coding agent. The agent is blocked and needs one decision from the user to keep going.

THE QUESTION: $question

Background, share only if they ask: $background

Rules:
- Talk fast and tight. Short sentences. No small talk.
- Ask the question. If the answer is vague, ask one follow-up.
- Repeat the decision back in one sentence and get them to confirm it.
- If they can't talk or say "you decide", say the agent will use its best judgment, then end the call.
- Never decide for them, promise anything, or discuss other topics.
- After they confirm, ask "Anything else before I let you go?" Only hang up once they say that's all. If they say "wait" or "hold on", stop and listen.
EOF
)
  body=$(jq -n \
    --arg phone "$phone" --arg task "$task" --arg q "$question" \
    --arg voice "${CALL_ME_VOICE:-}" --arg from "${CALL_ME_FROM:-}" '
    {
      phone_number: $phone,
      task: $task,
      first_sentence: "Hey, it'"'"'s your agent'"'"'s assistant. Got a sec for a quick question?",
      wait_for_greeting: true,
      max_duration: 8,
      interruptibility: 3,
      summary_prompt: "In 1-3 sentences, state exactly what the user decided or answered, including any conditions or extra instructions. If they gave no clear answer, say so. Add nothing they did not say.",
      voicemail: { action: "leave_message", message: ($q + " Check your agent when you can.") }
    }
    + (if $voice != "" then {voice: $voice} else {} end)
    + (if $from  != "" then {from: $from}   else {} end)')
  resp=$(bland POST /calls "$body")
  if [ "$(jq -r '.status // empty' <<<"$resp")" != success ]; then
    echo "call-me: Bland refused the call: $(jq -r '.message // .errors // .' <<<"$resp" 2>/dev/null || echo "$resp")" >&2
    exit 1
  fi
  jq -r .call_id <<<"$resp"
}

wait_call() {
  local id=$1 deadline=$(( SECONDS + ${CALL_ME_TIMEOUT:-540} )) resp ended=0 summary_deadline
  while [ $SECONDS -lt $deadline ]; do
    resp=$(bland GET "/calls/$id")
    if jq -e '.completed == true
              or (.queue_status // "" | test("complete|error"))
              or (.status // "" | test("^(failed|busy|no-answer|canceled)$"))' <<<"$resp" >/dev/null; then
      ended=1; break
    fi
    echo "call-me: $id still in progress (status=$(jq -r '.status // "?"' <<<"$resp"), queue=$(jq -r '.queue_status // "?"' <<<"$resp"))" >&2
    sleep 5
  done
  if [ $ended = 0 ]; then
    jq -n --arg id "$id" '{call_id: $id, outcome: "still_going", note: "Poll again with: call-me.sh wait <call_id>. Do not place a second call."}'
    return
  fi
  # The summary is generated after hang-up; give it up to a minute.
  summary_deadline=$(( SECONDS + 60 ))
  while [ -z "$(jq -r '.summary // empty' <<<"$resp")" ] && [ $SECONDS -lt $summary_deadline ]; do
    sleep 5; resp=$(bland GET "/calls/$id")
  done
  jq --arg id "$id" '{
    call_id: $id,
    outcome: (if .status == "completed" and (.answered_by // "") != "voicemail"
                 and ([.transcripts[]? | select(.user == "user")] | length > 0)
              then "answered"
              elif (.answered_by // "") == "voicemail" then "voicemail"
              else "no_answer_or_failed" end),
    status, answered_by, summary, concatenated_transcript
  }' <<<"$resp"
}

case ${1:-} in
  ask)  [ -n "${2:-}" ] || { echo 'usage: call-me.sh ask "<question>" ["<background>"]' >&2; exit 2; }
        id=$(place_call "$2" "${3:-none}"); echo "call-me: placed call $id" >&2; wait_call "$id" ;;
  wait) [ -n "${2:-}" ] || { echo 'usage: call-me.sh wait <call_id>' >&2; exit 2; }
        wait_call "$2" ;;
  *)    echo 'usage: call-me.sh ask "<question>" ["<background>"] | call-me.sh wait <call_id>' >&2; exit 2 ;;
esac
