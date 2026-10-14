package lcm_sum

// Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
euler_phi :: proc "contextless" (value: u64) -> u64 {
	result := value
	remaining := value
	factor := u64(2)
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

@(export)
lcm_sum :: proc "c" (input: i64) -> i64 {
	if input < 1 || input > 65535 do return -1
	n := u64(input)
	weighted_totients := u64(1)
	for divisor := u64(1); divisor <= n / divisor; divisor += 1 {
		if n % divisor == 0 {
			weighted_totients += divisor * euler_phi(divisor)
			paired := n / divisor
			if paired != divisor {
				weighted_totients += paired * euler_phi(paired)
			}
		}
	}
	return i64((weighted_totients * n) / 2)
}
