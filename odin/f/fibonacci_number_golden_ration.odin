package fibonacci_number_golden_ration

import "core:math"

@(export)
fibonacci_number_golden_ration :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > 70 do return -1
	if input <= 1 do return input

	sqrt5 := math.sqrt_f64(5.0)
	phi := (1.0 + sqrt5) / 2.0
	psi := (1.0 - sqrt5) / 2.0
	result := (math.pow_f64(phi, f64(input)) - math.pow_f64(psi, f64(input))) / sqrt5
	return i64(math.floor_f64(result + 0.5))
}
