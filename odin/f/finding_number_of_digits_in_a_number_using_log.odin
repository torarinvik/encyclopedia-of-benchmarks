package finding_number_of_digits_in_a_number_using_log

import "core:math"

MAX_ABS_VALUE :: 1_000_000.0
INVALID_RESULT :: f64 = -1.0e300

@(export)
finding_number_of_digits_in_a_number_using_log :: proc "c" (value: f64) -> f64 {
	if !(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE) do return INVALID_RESULT
	if value == 0.0 do return 0.0
	magnitude := if value < 0.0 { -value } else { value }
	return math.floor_f64(math.log10_f64(magnitude) + 1.0)
}
