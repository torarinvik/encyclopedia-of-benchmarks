module problem12

fn divisor_count(value i64) i64 {
	mut remaining := value
	mut factor := i64(2)
	mut count := i64(1)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			mut exponent := i64(0)
			for remaining % factor == 0 {
				remaining /= factor
				exponent++
			}
			count *= exponent + 1
		}
		factor++
	}
	if remaining > 1 { count *= 2 }
	return count
}

@[export: 'problem12']
pub fn problem12(minimum_divisors i64) i64 {
	if minimum_divisors < 0 || minimum_divisors > 500 { return -1 }
	mut index := i64(1)
	for index <= 12_375 {
		mut left := index
		mut right := index + 1
		if index % 2 == 0 { left /= 2 } else { right /= 2 }
		if divisor_count(left) * divisor_count(right) >= minimum_divisors {
			return index * (index + 1) / 2
		}
		index++
	}
	return -1
}
