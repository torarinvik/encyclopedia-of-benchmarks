module perfect_number

// Check whether n equals the sum of its positive proper divisors.
@[export: 'perfect_number']
pub fn perfect_number(n i64) i64 {
	if n <= 1 { return 0 }
	if n > 1_000_000_000_000 { return -1 }

	mut divisor_sum := i64(1)
	mut factor := i64(2)
	for factor <= n / factor {
		if n % factor == 0 {
			divisor_sum += factor
			partner := n / factor
			if partner != factor { divisor_sum += partner }
			if divisor_sum > n { return 0 }
		}
		factor++
	}
	return if divisor_sum == n { i64(1) } else { i64(0) }
}
