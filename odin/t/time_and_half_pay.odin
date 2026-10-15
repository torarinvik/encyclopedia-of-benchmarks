package time_and_half_pay

// Time and a half pay following the pinned Python calculation order.
@(export)
time_and_half_pay :: proc "c" (hours_worked, pay_rate, threshold_hours: f64) -> f64 {
	if !(hours_worked >= 0 && hours_worked <= 1000 && pay_rate >= 0 && pay_rate <= 1000 && threshold_hours >= 0 && threshold_hours <= 1000) do return -1e300
	normal_pay := hours_worked * pay_rate
	over_time := hours_worked - threshold_hours
	if over_time < 0 do over_time = 0
	over_time_pay := over_time * pay_rate / 2
	return normal_pay + over_time_pay
}
