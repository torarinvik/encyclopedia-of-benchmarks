package minkowski_distance

import "core:c"
import "core:math"

MAX_N :: i64(8)
MAX_P :: i64(6)
INVALID_RESULT :: f64 = -1.0e300

@(export)
minkowski_distance :: proc "c" (packed: [^]i64, length: c.size_t) -> f64 {
	if packed == nil || length < 2 || length > 18 do return INVALID_RESULT
	n := packed[0]
	p := packed[1]
	if n < 0 || n > MAX_N || p < 3 || p > MAX_P || length != c.size_t(2 + 2 * n) do return INVALID_RESULT
	for index := i64(0); index < n; index += 1 {
		if packed[2 + index] < -100 || packed[2 + index] > 100 || packed[2 + n + index] < -100 || packed[2 + n + index] > 100 do return INVALID_RESULT
	}
	total := i64(0)
	for index := i64(0); index < n; index += 1 {
		difference := packed[2 + index] - packed[2 + n + index]
		if difference < 0 { difference = -difference }
		term := i64(1)
		for exponent := i64(0); exponent < p; exponent += 1 { term *= difference }
		total += term
	}
	return math.pow(f64(total), 1.0 / f64(p))
}
