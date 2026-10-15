package babylonian_sqrt

absolute :: proc "contextless" (value: f64) -> f64 {
	if value < 0.0 do return -value
	return value
}

@(export)
babylonian_sqrt :: proc "c" (input: f64) -> f64 {
	if !(input >= 0.0 && input <= 1_000_000.0) do return -1.0
	estimate := input / 2.0
	tolerance := 0.000001
	for tolerance <= absolute(estimate * estimate - input) {
		estimate = 0.5 * (estimate + input / estimate)
	}
	return estimate
}
