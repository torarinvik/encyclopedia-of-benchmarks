package problem27

problem27_is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	if value % 3 == 0 do return value == 3
	factor := i64(5)
	for factor <= value / factor {
		if value % factor == 0 || value % (factor + 2) == 0 do return false
		factor += 6
	}
	return true
}

@(export)
problem27 :: proc "c" (limit: i64) -> i64 {
	if limit < 1 || limit > 1000 do return -1
	best_length := i64(0)
	best_a := i64(0)
	best_b := i64(0)
	for a := 1 - limit; a < limit; a += 1 {
		for b := i64(2); b < limit; b += 1 {
			if !problem27_is_prime(b) do continue
			n := i64(0)
			for problem27_is_prime(n * n + a * n + b) {
				n += 1
			}
			if n > best_length {
				best_length = n
				best_a = a
				best_b = b
			}
		}
	}
	return best_a * best_b
}
