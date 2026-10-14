module aliquot_sum

// Scan proper divisors under the shared signed 64-bit contract.
@[export: 'aliquot_sum']
pub fn aliquot_sum(n i64) i64 {
	if n < 0 { return -1 }
	mut total := i64(0)
	mut divisor := i64(1)
	for divisor <= n / 2 {
		if n % divisor == 0 {
			if total > i64(9223372036854775807) - divisor { return -1 }
			total += divisor
		}
		divisor++
	}
	return total
}
