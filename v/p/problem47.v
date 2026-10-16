module problem47

fn distinct_prime_factor_count(value_input i64) i64 {
	mut value := value_input
	mut count := i64(0)
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 {
			count++
			for value % divisor == 0 {
				value /= divisor
			}
		}
		divisor++
	}
	if value > 1 { count++ }
	return count
}

@[export: 'problem47']
pub fn problem47(n i64) i64 {
	if n < 1 || n > 4 { return -1 }
	mut value := i64(2)
	mut run_length := i64(0)
	for {
		if distinct_prime_factor_count(value) == n { run_length++ }
		else { run_length = 0 }
		if run_length == n { return value - n + 1 }
		value++
	}
}
