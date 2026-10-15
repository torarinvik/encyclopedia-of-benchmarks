## Time and a half pay following the pinned Python calculation order.
proc time_and_half_pay*(hours_worked, pay_rate, threshold_hours: float64): float64 {.cdecl, exportc: "time_and_half_pay".} =
  if not (hours_worked >= 0.0 and hours_worked <= 1000.0 and pay_rate >= 0.0 and pay_rate <= 1000.0 and threshold_hours >= 0.0 and threshold_hours <= 1000.0): return -1e300
  let normal_pay = hours_worked * pay_rate
  var over_time = hours_worked - threshold_hours
  if over_time < 0.0: over_time = 0.0
  let over_time_pay = over_time * pay_rate / 2.0
  normal_pay + over_time_pay
