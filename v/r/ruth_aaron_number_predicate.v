module main

const max_n = i64(100000)
const max_parseable_length = usize(2)

fn factor_sum_counted(value_arg i64) i64 {
	mut value := value_arg
	mut total := i64(0)
	mut divisor := i64(2)
	for divisor <= value / divisor {
		for value % divisor == 0 {
			total += divisor
			value /= divisor
		}
		divisor++
	}
	if value > 1 { total += value }
	return total
}

@[export: 'ruth_aaron_number_predicate']
pub fn ruth_aaron_number_predicate(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 { return -1 }
		n := input[0]
		if n < 1 || n > max_n { return -1 }
		if factor_sum_counted(n) == factor_sum_counted(n + 1) { return 1 }
		return 0
	}
}
