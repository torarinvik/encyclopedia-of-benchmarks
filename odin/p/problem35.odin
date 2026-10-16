package problem35

MAX_LIMIT :: 1_000_000
ODD_SLOTS :: MAX_LIMIT / 2 + 1

@(export)
problem35 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	odd_prime: [ODD_SLOTS]bool = {}
	for index := 1; index < ODD_SLOTS; index += 1 { odd_prime[index] = true }

	for candidate := 3; candidate <= MAX_LIMIT / candidate; candidate += 2 {
		if odd_prime[candidate / 2] {
			for composite := candidate * candidate; composite <= MAX_LIMIT; composite += 2 * candidate {
				odd_prime[composite / 2] = false
			}
		}
	}

	count: i64 = 1
	for number := 3; number <= MAX_LIMIT; number += 2 {
		if !odd_prime[number / 2] { continue }
		remaining := number
		has_even_digit := false
		for remaining > 0 {
			if (remaining % 10) % 2 == 0 {
				has_even_digit = true
				break
			}
			remaining /= 10
		}
		if has_even_digit { continue }

		power10, digits := 1, 1
		remaining = number
		for remaining >= 10 {
			power10 *= 10
			remaining /= 10
			digits += 1
		}
		rotation := number
		circular := true
		for turn := 0; turn < digits; turn += 1 {
			if !odd_prime[rotation / 2] {
				circular = false
				break
			}
			rotation = (rotation % 10) * power10 + rotation / 10
		}
		if circular { count += 1 }
	}
	return count
}
