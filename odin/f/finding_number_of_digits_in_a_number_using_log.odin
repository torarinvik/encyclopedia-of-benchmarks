package finding_number_of_digits_in_a_number_using_log

import "core:math"

MAX_ABS_VALUE :: i64(1_000_000)

@(export)
finding_number_of_digits_in_a_number_using_log :: proc "c" (value: i64) -> i64 {
	if value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE do return -1
	if value == 0 do return 0
	magnitude := f64(value)
	if magnitude < 0.0 do magnitude = -magnitude
	return i64(math.floor_f64(math.log10_f64(magnitude) + 1.0))
}
