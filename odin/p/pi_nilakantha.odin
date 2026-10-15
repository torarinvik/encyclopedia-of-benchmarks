package pi_nilakantha

@(export)
pi_nilakantha :: proc "c" (input: f64) -> f64 {
	if !(input >= 0.0 && input <= 500.0 && input == f64(i32(input))) do return -1.0
	iterations := i32(input)
	pi := 3.0
	div_counter := i32(2)
	for i in 0 .. iterations {
		term := 4.0 / f64(div_counter * (div_counter + 1) * (div_counter + 2))
		if i % 2 == 0 {
			pi = pi + term
		} else {
			pi = pi - term
		}
		div_counter += 2
	}
	return pi
}
