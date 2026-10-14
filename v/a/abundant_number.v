@[export: 'abundant_number']
fn abundant_number(n i64) i64 {
	if n < 1 || n > 1_000_000_000 { return -1 }
	if n == 1 { return 0 }
	mut sum := i64(1)
	mut divisor := i64(2)
	for divisor <= n / divisor {
		if n % divisor == 0 {
			sum += divisor
			partner := n / divisor
			if partner != divisor { sum += partner }
			if sum > n { return 1 }
		}
		divisor++
	}
	return 0
}
