module square_root_with_newton_raphson_method

import math

const invalid_result = -1.0e300
const max_input = 2147483647.0

@[export: 'square_root_with_newton_raphson_method']
pub fn square_root_with_newton_raphson_method(input f64) f64 {
	if math.is_nan(input) || input < 1.0 || input > max_input { return invalid_result }
	if f64(i64(input)) != input { return invalid_result }
	mut guess := input
	mut root := 0.5 * (guess + input / guess)
	for math.abs(root - guess) > 1e-7 {
		guess = root
		root = 0.5 * (guess + input / guess)
	}
	return root
}
