package gaussian_error_linear_unit_tanh

import "core:math"

INVALID_RESULT :: -1.0e300
PI_VALUE :: 3.14159265358979323846264338327950288
E_VALUE :: 2.71828182845904523536028747135266250

@(export)
gaussian_error_linear_unit_tanh :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -100.0 || x > 100.0 do return INVALID_RESULT
	scale := math.pow(2.0 / PI_VALUE, 0.5)
	z := scale * (x + 0.044715 * math.pow(x, 3.0))
	tanh_value := 2.0 / (1.0 + math.pow(E_VALUE, -2.0 * z)) - 1.0
	return x * 0.5 * (1.0 + tanh_value)
}
