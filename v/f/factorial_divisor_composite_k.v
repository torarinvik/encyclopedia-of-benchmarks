module factorial_divisor_composite_k

fn factorial_divisor_composite_k_valuation(mut n u64, prime u64) u64 {
	mut total := u64(0)
	for n != 0 {
		n /= prime
		total += n
	}
	return total
}

@[export: 'factorial_divisor_composite_k']
pub fn factorial_divisor_composite_k(n u64, k u64) i64 {
	if n > 1_000_000_000_000 || k < 4 || k > 1_000_000 {
		return -1
	}
	mut remaining := k
	mut divisor := u64(2)
	mut answer := n
	mut composite := false
	for divisor <= remaining / divisor {
		if remaining % divisor == 0 {
			composite = true
			mut exponent := u64(0)
			for remaining % divisor == 0 {
				remaining /= divisor
				exponent++
			}
			candidate := factorial_divisor_composite_k_valuation(n, divisor) / exponent
			if candidate < answer {
				answer = candidate
			}
		}
		divisor++
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
