package problem120

const MAX_LIMIT: i64 = 1000

@(export)
problem120 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > MAX_LIMIT do return -1
	total := i64(0)
	for a := i64(3); a <= limit; a += 1 { total += 2 * a * ((a - 1) / 2) }
	return total
}
