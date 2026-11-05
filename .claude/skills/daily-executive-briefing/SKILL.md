---
name: daily-executive-briefing
description: Create a verified UAE-time daily briefing from calendar, email, tasks and project data when asked for today’s plan or priorities.
---

# Daily Executive Briefing

## Trigger
Use for “Good morning”, “my daily plan”, “what is important today?”, “brief me”, or a requested daily schedule.

## Workflow
1. Determine the **current Asia/Dubai date and time** using an available time source. Avoid treating historical notes as today's facts.
2. Inspect available connected calendar, inbox, task tracker, and business project files. Use read-only calls first. State exactly which sources were checked and their coverage/freshness. If no connector exists, use user-provided inputs; label the output **Preliminary — unverified**.
3. Normalize actionable items into unique tasks with owner, next action, verified deadline, status, source link, and dependency. Do not infer deadlines from a general topic or earlier example.
4. Apply the `smart-task-prioritizer` skill if present; otherwise assign P0/P1/P2/P3 by safety/compliance impact, deadlines, dependencies, and material exposure. Never invent urgency.
5. Check for interview or meeting conflicts, travel, preparation, deadlines, waiting-on items, and availability before creating an hourly plan.
6. Present the brief in the template at `assets/daily-briefing-template.md`. If dates lack a time, retain **date only**. If a calendar is unavailable, propose time blocks labeled **Suggested, not calendar confirmed**.
7. End with one actionable recommendation: **Do this next: ...**

## Required sections
- Date and last verified time (Asia/Dubai)
- Sources checked / not checked
- Executive summary (2–4 sentences)
- Top 5 actions with priority, owner, due, effort, next step
- Overdue and due today, if confirmed
- Meetings & preparation; email requiring response
- Finance approvals; café operations; active software releases (only when evidence exists)
- Waiting for others and recommended delegation
- Suggested schedule that respects known commitments
- Tomorrow's preparation

## Safety and uncertainty
- Reading a message does not establish that it is urgent; use explicit commitments and dates.
- Never assume tasks are complete or that a message has been sent.
- Use “Not checked” rather than “Nothing pending” when source access is absent.
- Ask permission before creating calendar events, sending communications, modifying records, payments, or production systems.
- Do not reveal personal addresses, staff private data or sensitive account details in a shareable summary.

## Example invocations
“Hey My Assistant, give me today’s UAE daily briefing.”
“Build my schedule around tomorrow’s interviews and my café responsibilities.”
