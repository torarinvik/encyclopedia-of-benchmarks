package factorial_divisor_composite_k

factorial_divisor_composite_k_valuation :: proc(n, prime: u64) -> u64 {
	quotient := n
	total: u64 = 0
	for quotient != 0 {
		quotient /= prime
		total += quotient
	}
	return total
}

@(export)
factorial_divisor_composite_k :: proc "c" (n, k: u64) -> i64 {
	if n > 1_000_000_000_000 || k < 4 || k > 1_000_000 {
		return -1
	}

	remaining := k
	divisor: u64 = 2
	answer := n
	composite := false
	for divisor <= remaining / divisor {
		if remaining % divisor == 0 {
			composite = true
			exponent: u64 = 0
			for remaining % divisor == 0 {
				remaining /= divisor
				exponent += 1
			}
			candidate := factorial_divisor_composite_k_valuation(n, divisor) / exponent
			if candidate < answer {
				answer = candidate
			}
		}
		divisor += 1
	}

	if !composite {
		return -1
	}
	if remaining > 1 {
		candidate := factorial_divisor_composite_k_valuation(n, remaining)
		if candidate < answer {
			answer = candidate
		}
	}
	return i64(answer)
}
