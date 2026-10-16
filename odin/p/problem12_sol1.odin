package problem12_sol1

divisor_count :: proc "contextless" (value: i64) -> i64 {
	remaining := value
	factor := i64(2)
	count := i64(1)
	for factor <= remaining / factor {
		multiplicity := i64(0)
		for remaining % factor == 0 {
			remaining /= factor
			multiplicity += 1
		}
		if multiplicity > 0 do count *= multiplicity + 1
		factor += 1
	}
	if remaining > 1 do count *= 2
	return count
}

@(export)
problem12_sol1 :: proc "c" (threshold: i64) -> i64 {
	if threshold != 500 do return -1
	index := i64(1)
	triangular := i64(1)
	for {
		index += 1
		triangular += index
		if divisor_count(triangular) > 500 do return triangular
	}
	return -1
}
