module fibonacci_number_golden_ration

import math

@[export: 'fibonacci_number_golden_ration']
pub fn fibonacci_number_golden_ration(input i64) i64 {
	if input < 0 || input > 70 {
		return -1
	}
	if input <= 1 {
		return input
	}
	sqrt5 := math.sqrt(5.0)
	phi := (1.0 + sqrt5) / 2.0
	psi := (1.0 - sqrt5) / 2.0
	result := (math.pow(phi, f64(input)) - math.pow(psi, f64(input))) / sqrt5
	return i64(math.floor(result + 0.5))
}
