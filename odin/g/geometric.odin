package geometric

import "core:c"
import "core:math"

GEOMETRIC_INVALID_RESULT :: -1.0e300

// Operation 0 tests a geometric sequence; operation 1 computes its mean.
@(export)
geometric :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 do return GEOMETRIC_INVALID_RESULT
	operation := values[0]
	count := length - 1
	if operation == 0 {
		if count > 16 do return GEOMETRIC_INVALID_RESULT
		for index := c.size_t(1); index < length; index += 1 {
			if values[index] < -100 || values[index] > 100 do return GEOMETRIC_INVALID_RESULT
		}
		if count == 1 do return 1.0
		if values[1] == 0 do return 0.0
		common_ratio := f64(values[2]) / f64(values[1])
		for index := c.size_t(0); index + 1 < count; index += 1 {
			if values[index + 1] == 0 do return 0.0
			if f64(values[index + 2]) / f64(values[index + 1]) != common_ratio do return 0.0
		}
		return 1.0
	}
	if operation == 1 {
		if count > 7 do return GEOMETRIC_INVALID_RESULT
		product := i64(1)
		for index := c.size_t(1); index < length; index += 1 {
			if values[index] < 0 || values[index] > 100 do return GEOMETRIC_INVALID_RESULT
			product *= values[index]
		}
		return math.pow_f64(f64(product), 1.0 / f64(count))
	}
	return GEOMETRIC_INVALID_RESULT
}
