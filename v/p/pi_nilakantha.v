module pi_nilakantha

@[export: 'pi_nilakantha']
pub fn pi_nilakantha(input f64) f64 {
	if !(input >= 0.0 && input <= 500.0 && input == f64(int(input))) { return -1.0 }
	iterations := int(input)
	mut pi := 3.0
	mut div_counter := 2
	for i in 0 .. iterations {
		term := 4.0 / f64(div_counter * (div_counter + 1) * (div_counter + 2))
		if i % 2 == 0 { pi = pi + term } else { pi = pi - term }
		div_counter += 2
	}
	return pi
}
