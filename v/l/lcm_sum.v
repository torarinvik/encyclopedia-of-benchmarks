module lcm_sum

fn euler_phi(value u64) u64 {
	mut result := value
	mut remaining := value
	mut factor := u64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			result -= result / factor
			for remaining % factor == 0 {
				remaining /= factor
			}
		}
		if factor == 2 {
			factor = 3
		} else {
			factor += 2
		}
	}
	if remaining > 1 {
		result -= result / remaining
	}
	return result
}

// Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
@[export: 'lcm_sum']
pub fn lcm_sum(input i64) i64 {
	if input < 1 || input > 65535 { return -1 }
	n := u64(input)
	mut weighted_totients := u64(1)
	mut divisor := u64(1)
	for divisor <= n / divisor {
		if n % divisor == 0 {
			weighted_totients += divisor * euler_phi(divisor)
			paired := n / divisor
			if paired != divisor { weighted_totients += paired * euler_phi(paired) }
		}
		divisor++
	}
	return i64((weighted_totients * n) / 2)
}
