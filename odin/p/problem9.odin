package problem9

@(export)
problem9 :: proc "c" (total: i64) -> i64 {
	if total < 3 || total > 1000 do return -1
	for a := i64(1); a <= total / 3; a += 1 {
		for b := a + 1; 2 * b < total - a; b += 1 {
			c := total - a - b
			if a * a + b * b == c * c do return a * b * c
		}
	}
	return -1
}
