package mobius_function

@(export)
mobius_function :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > 10000 do return -9223372036854775807 - 1
	remaining := n
	distinct_factor_count: i64 = 0
	for factor := i64(2); factor * factor <= remaining; factor += 1 {
		if remaining % factor == 0 {
			remaining /= factor
			if remaining % factor == 0 do return 0
			distinct_factor_count += 1
		}
	}
	if remaining > 1 do distinct_factor_count += 1
	if distinct_factor_count % 2 == 0 do return 1
	return -1
}
