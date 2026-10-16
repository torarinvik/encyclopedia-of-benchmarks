package liouville

// Go's distinct-factor Liouville variant: (-1) raised to omega(n).
@(export)
liouville :: proc "c" (input: i64) -> i64 {
	if input < 1 || input > 2_147_483_647 do return -2
	remaining := u64(input)
	sign := i64(1)
	factor := u64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			sign = -sign
			for remaining % factor == 0 { remaining /= factor }
		}
		if factor == 2 { factor = 3 } else { factor += 2 }
	}
	if remaining > 1 { sign = -sign }
	return sign
}
