# Pomodoro

## TODO

- [x] Show as a clock
- [x] Add live-reload
- [x] Add slack controls
- [ ] Re-add launcher
- [ ] Extract out a pomodoro module somewhere (timer_core?) (or just remove timer_core?)
  - This is in the vein of the thought "scenic is not your app"
  - Should also pave the way for an html rendering of the same timer
- [ ] Provide a toggle to select if slack status will be updated
- [ ] Don't compile the SLACK_TOKEN into the code, instead read it from a secrets file

Maybe:
- [ ] Play a bell sound when the timer finishes
- [ ] Pull in sched_ex for more accurate timer
