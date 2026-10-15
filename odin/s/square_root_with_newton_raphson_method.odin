package square_root_with_newton_raphson_method

import "core:math"

INVALID_RESULT :: -1.0e300
MAX_INPUT :: 2147483647.0

@(export)
square_root_with_newton_raphson_method :: proc "c" (input: f64) -> f64 {
	if math.is_nan_f64(input) || input < 1.0 || input > MAX_INPUT do return INVALID_RESULT
	if f64(i64(input)) != input do return INVALID_RESULT
	guess := input
	root := 0.5 * (guess + input / guess)
	for math.abs(root - guess) > 1e-7 {
		guess = root
		root = 0.5 * (guess + input / guess)
	}
	return root
}
