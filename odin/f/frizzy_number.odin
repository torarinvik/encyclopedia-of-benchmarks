package frizzy_number

// Sum base powers at the set-bit positions of n.
@(export)
frizzy_number :: proc "c" (base, n: i64) -> i64 {
	if base < 2 || base > 10 || n < 0 || n > 1023 {
		return -1
	}
	remaining := n
	result: i64 = 0
	power: i64 = 1
	for remaining > 0 {
		if remaining % 2 == 1 {
			result += power
		}
		remaining /= 2
		if remaining > 0 {
			power *= base
		}
	}
	return result
}
