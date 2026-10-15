package pronic_number

import "core:math"

@(export)
pronic_number :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 2_147_483_647 do return -1
	root := i64(math.sqrt(f64(n)))
	if root * (root + 1) == n do return 1
	return 0
}
