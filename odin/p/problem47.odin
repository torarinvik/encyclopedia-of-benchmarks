package problem47

distinct_prime_factor_count :: proc(value_input: i64) -> i64 {
	value := value_input
	count: i64 = 0
	divisor: i64 = 2
	for divisor * divisor <= value {
		if value % divisor == 0 {
			count += 1
			for value % divisor == 0 {
				value /= divisor
			}
		}
		divisor += 1
	}
	if value > 1 { count += 1 }
	return count
}

@(export)
problem47 :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > 4 { return -1 }
	value: i64 = 2
	run_length: i64 = 0
	for {
		if distinct_prime_factor_count(value) == n { run_length += 1 }
		else { run_length = 0 }
		if run_length == n { return value - n + 1 }
		value += 1
	}
}
