module friendly_number

fn sum_divisors(number u64) i64 {
	mut sum := i64(0)
	mut divisor := u64(1)
	for divisor * divisor <= number {
		if number % divisor == 0 {
			sum += i64(divisor)
			other := number / divisor
			if other != divisor { sum += i64(other) }
		}
		divisor++
	}
	return sum
}

@[export: 'friendly_number']
pub fn friendly_number(a u64, b u64) i64 {
	if a > 1_000_000 || b > 1_000_000 { return -1 }
	if a == 0 || b == 0 { return 0 }
	sigma_a := sum_divisors(a)
	sigma_b := sum_divisors(b)
	if sigma_a * i64(b) == sigma_b * i64(a) { return 1 }
	return 0
}
