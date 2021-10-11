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
- [x] Provide a toggle to select if slack status will be updated
- [x] Show the amount of time spent in limbo (always or only if it's over a threshold?)
- [x] Play a bell sound when the timer finishes
- [x] Check if Scenic.Viewport.Status should actually be exposed (since it is returned from the public method Scenic.ViewPort.info)
- [ ] Use Scenic.PubSub instead of Process.send directly

Maybe:
- [ ] Pull in sched_ex for more accurate timer
- [ ] Split out the pomodoro timer module from the GenServer
