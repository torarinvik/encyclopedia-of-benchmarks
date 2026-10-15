package distance_between_two_points

import "core:c"
import "core:math"

MAX_COORDINATE :: i64(1_000_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
distance_between_two_points :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	for index := 0; index < 4; index += 1 {
		if values[index] < -MAX_COORDINATE || values[index] > MAX_COORDINATE do return INVALID_RESULT
	}
	dx := f64(values[2] - values[0])
	dy := f64(values[3] - values[1])
	return math.sqrt(dx * dx + dy * dy)
}
