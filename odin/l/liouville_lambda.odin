package liouville_lambda

// Liouville's function: (-1) raised to the number of prime factors with multiplicity.
@(export)
liouville_lambda :: proc "c" (input: i64) -> i64 {
	if input < 1 || input > 2_147_483_647 do return -1
	remaining := u64(input)
	sign := i64(1)
	factor := u64(2)
	for factor <= remaining / factor {
		for remaining % factor == 0 {
			remaining /= factor
			sign = -sign
		}
		if factor == 2 { factor = 3 } else { factor += 2 }
	}
	if remaining > 1 { sign = -sign }
	return sign
}
