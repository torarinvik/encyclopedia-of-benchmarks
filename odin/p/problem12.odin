package problem12

divisor_count :: proc(value: i64) -> i64 {
	remaining := value
	factor := i64(2)
	count := i64(1)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			exponent := i64(0)
			for remaining % factor == 0 {
				remaining /= factor
				exponent += 1
			}
			count *= exponent + 1
		}
		factor += 1
	}
	if remaining > 1 do count *= 2
	return count
}

@(export)
problem12 :: proc "c" (minimum_divisors: i64) -> i64 {
	if minimum_divisors < 0 || minimum_divisors > 500 do return -1
	for index := i64(1); index <= 12_375; index += 1 {
		left := index
		right := index + 1
		if index % 2 == 0 {
			left /= 2
		} else {
			right /= 2
		}
		if divisor_count(left) * divisor_count(right) >= minimum_divisors
			do return index * (index + 1) / 2
	}
	return -1
}
