package geometric_mean

import "core:c"
import "core:math"

MAX_LENGTH :: 6
MAX_ABS_VALUE :: i64(100)
INVALID_RESULT :: f64 = -1.0e300

@(export)
geometric_mean :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
	product := i64(1)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE do return INVALID_RESULT
		product *= value
	}
	if product < 0 && length % 2 == 0 do return INVALID_RESULT
	root := math.pow(math.abs(f64(product)), 1.0 / f64(length))
	rounded := math.floor(root + 0.5)
	rounded_power := i64(1)
	for index := c.size_t(0); index < length; index += 1 {
		rounded_power *= i64(rounded)
	}
    if (product >= 0 && rounded_power == product) || (product < 0 && length % 2 == 1 && -rounded_power == product) do root = rounded
	if product < 0 do root = -root
	return root
}
