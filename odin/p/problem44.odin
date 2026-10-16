package problem44

import "core:math"

is_pentagonal :: proc "contextless" (value: i64) -> bool {
	if value < 1 do return false
	discriminant := 24 * value + 1
	root := i64(math.sqrt(f64(discriminant)))
	return root * root == discriminant && (root + 1) % 6 == 0
}

@(export)
problem44 :: proc "c" (limit: i64) -> i64 {
	if limit < 1 || limit > 5000 do return -1
	for i := i64(1); i < limit; i += 1 {
		first := i * (3 * i - 1) / 2
		for j := i; j < limit; j += 1 {
			second := j * (3 * j - 1) / 2
			difference := second - first
			if is_pentagonal(first + second) && is_pentagonal(difference) do return difference
		}
	}
	return -1
}
