package problem190

import "core:math"

MAX_N :: 15

@(export)
problem190 :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_N do return -1
	total := i64(0)
	for m := i64(2); m <= n; m += 1 {
		x1 := 2.0 / f64(m + 1)
		product := 1.0
		for i := i64(1); i <= m; i += 1 {
			xi := f64(i) * x1
			product *= math.pow_f64(xi, f64(i))
		}
		total += i64(product)
	}
	return total
}
