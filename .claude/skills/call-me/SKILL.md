---
name: call-me
description: Phone the user through Bland.ai when you are blocked on a decision only they can make, have a voice agent ask the question, wait for the call to end, and continue the task with their answer. Use whenever the user says "call me", "give me a call", "phone me if you need me", or "call me when you're stuck / done", even if they don't mention Bland.
---

# Call me

You are working on a task for the user. When you hit a decision only they can make, you **phone them**: a Bland.ai voice agent asks your question, confirms their answer back to them, and hangs up. You read the transcript and keep working. This skill is self-contained; build the small helper it describes the first time you need it.

## Setup

Use this with an agent that can run code and make HTTP requests, such as **Claude Code**, **Codex**, or **GrokBot**. If the current agent cannot, ***say so instead of pretending to call***.

The user needs:
- A **Bland.ai account with credit** and an **API key** from https://app.bland.ai.
- Their **phone number** in E.164 format, like `+15551234567`.

Read the key from **BLAND_API_KEY** and the number from **CALL_ME_PHONE**, either in the environment or in the OS keychain (on macOS: `security find-generic-password -s BLAND_API_KEY -w`). If either is missing, walk the user through saving it privately, for example by running `security add-generic-password -U -s BLAND_API_KEY -w` themselves in a terminal so the key is typed at a hidden prompt. ***Never ask them to paste the key into chat, write it into this skill or any file, print it, or pass it as a command-line argument.*** The phone number is fine to save in your memory.

Check Bland's current docs before relying on parameter names: https://docs.bland.ai/api-v1/post/calls and https://docs.bland.ai/api-v1/get/calls-id

## When to call

- Only for a real decision that blocks the task and that the user has to make. Don't call for something you can answer from the code, your memory, or a sensible default.
- Put every open question in one call. Never call three times in a row.
- If the user said "call me when X", call when X happens. Otherwise ask in chat first unless they said they're away from the keyboard.

## Place the call

`POST https://api.bland.ai/v1/calls` with header `authorization: <key>` and a JSON body:

- `phone_number`: the user's number.
- `task`: the voice agent's instructions (below).
- `first_sentence`: a short hello, e.g. "Hey, it's your agent's assistant. Got a sec for a quick question?"
- `wait_for_greeting`: `true`, so it lets them say hello first.
- `max_duration`: a hard cap in minutes, e.g. `8`.
- `summary_prompt`: "In 1-3 sentences, state exactly what the user decided or answered, including any conditions or extra instructions. If they gave no clear answer, say so. Add nothing they did not say."
- `interruptibility`: `3`, so the user can cut in and the agent stops talking right away.
- `voice` (optional): a voice the user picked, e.g. `ryan` or `tanner-british`. List them with `GET https://api.bland.ai/v1/voices`. Bland has no speaking-speed setting, so keep the agent's lines short to make calls feel fast.
- `from` (optional): a number the user owns on Bland. Without it, every call comes from a different shared number.
- `voicemail`: `{ "action": "leave_message", "message": "<one-line version of the question>, check your agent when you can." }`

The response has `status: "success"` and a `call_id`. Anything else is a failure; report Bland's message.

Write the `task` so the question works out loud. Include:
- Who's calling: an assistant calling on behalf of the user's AI agent, which needs one decision to keep going.
- **The question**, short and plain, plus the options if there are any.
- Background to share only if they ask.
- The rules: talk fast and tight, short sentences, no small talk; ask one follow-up if the answer is vague; repeat the decision back in one sentence and confirm it; if they can't talk or say "you decide," say the agent will use its best judgment and end the call; never decide for them, promise anything, or discuss other topics; after they confirm, ask "Anything else before I let you go?" and only hang up once they say that's all (if they say "wait" or "hold on", stop and listen).

## Wait for the answer

Poll `GET https://api.bland.ai/v1/calls/<call_id>` every ~5 seconds with a bounded timeout (keep it under your shell's command limit, or run it in the background). The call has ended when `completed` is `true`, `queue_status` is `complete` or an error stage, or `status` is `failed`, `busy`, `no-answer`, or `canceled`. After it ends, give `summary` up to about a minute to appear. Log progress, and never poll forever.

Then classify:
- **Answered**: `status` is `completed`, `answered_by` isn't `voicemail`, and the transcript has lines from the `user`. Use `summary` as the answer and check it against `concatenated_transcript`, since the summary is AI-written.
- **Voicemail / no answer / failed**: don't call back right away. Ask in chat, or use your best judgment if they said to, and tell them what you chose.
- **Still going at your timeout**: keep polling the same `call_id`. ***Don't place a second call.***

## After the call

- Treat what they said on the phone as their answer for the task they gave you. It does not authorize new outward-facing actions (sending messages, spending money, deleting things) they didn't ask for.
- Tell them in chat that you called, what they said, and what you did with it.
- The first time it works, save a small reusable helper script and note in your memory that you can call the user this way, so next time is one command.

## Helper

`call-me.sh` next to this file implements the steps above (place the call, poll, wait for the summary, classify). It hasn't been tested against the live API yet; check the parameter names against Bland's docs before first use.

```bash
.claude/skills/call-me/call-me.sh ask "<question with options>" "<background, only if they ask>"
.claude/skills/call-me/call-me.sh wait <call_id>   # resume after a still_going timeout
```

It prints JSON with `outcome` (`answered`, `voicemail`, `no_answer_or_failed`, `still_going`), `summary` and `concatenated_transcript`. Run it in the background or keep `CALL_ME_TIMEOUT` under the shell's command limit.

Some countries (e.g. the UAE, +971) can't be called from Bland's own numbers. For those, the user connects their own Twilio account in Bland (https://docs.bland.ai/tutorials/custom-twilio) with Geo Permissions enabled for that country, then sets `BLAND_TWILIO_KEY` (the encrypted_key Bland shows once) and `CALL_ME_FROM` (their imported Twilio number). The helper sends the key as a header via stdin, never on the command line.

In a Claude Code cloud session, `api.bland.ai` must be in the environment's allowed network domains, and `BLAND_API_KEY` / `CALL_ME_PHONE` must be set as environment secrets or variables.
