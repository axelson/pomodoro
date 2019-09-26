# Pomodoro

## TODO

- [x] Show as a clock
- [x] Add live-reload
- [x] Add slack controls
- [x] Color should change as soon as you tap
- [x] bug: Double clicks cause duplicate registrations
- [x] Re-add launcher
- [x] Re-add slack integration
- [x] Add an explicit Rest button
- [x] Extract out a pomodoro module somewhere (timer_core?) (or just remove timer_core?)
  - This is in the vein of the thought "scenic is not your app"
  - Should also pave the way for an html rendering of the same timer
- [ ] Provide a toggle to select if slack status will be updated
- [ ] Allow configuring slack integration from the web?
- [ ] Don't compile the SLACK_TOKEN into the code, instead read it from a secrets file
- [ ] Show the amount of time spent in limbo (always or only if it's over a threshold?)

Maybe:
- [ ] Play a bell sound when the timer finishes
- [ ] Pull in sched_ex for more accurate timer
