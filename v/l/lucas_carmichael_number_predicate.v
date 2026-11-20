module lucas_carmichael_number_predicate

const max_value = i64(1_000_000)

@[export: 'lucas_carmichael_number_predicate']
pub fn lucas_carmichael_number_predicate(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	value := unsafe { input[0] }
	if value < 1 || value > max_value { return -1 }

	mut remaining := value
	mut divisor := i64(2)
	mut composite := false
	for divisor <= remaining / divisor {
		if remaining % divisor == 0 {
			composite = true
			mut exponent := 0
			for remaining % divisor == 0 {
				remaining /= divisor
				exponent++
			}
			if exponent != 1 || (value + 1) % (divisor + 1) != 0 { return 0 }
		}
		divisor++
	}
	if remaining > 1 {
		if !composite || (value + 1) % (remaining + 1) != 0 { return 0 }
	}
	if composite { return 1 }
	return 0
}
