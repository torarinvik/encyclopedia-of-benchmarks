module arithmetic_derivative

const max_n = i64(1_000_000_000_000)
const max_parseable_length = 2

fn ad_from_factors(value i64) i64 {
	if value < 2 { return 0 }
	original := value
	mut remaining := value
	mut derivative := i64(0)
	mut factor := i64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			mut exponent := i64(0)
			for remaining % factor == 0 {
				remaining /= factor
				exponent++
			}
			derivative += (original / factor) * exponent
		}
		if factor == 2 { factor = 3 }
		else { factor += 2 }
	}
	if remaining > 1 { derivative += original / remaining }
	return derivative
}

@[export: 'arithmetic_derivative']
pub fn arithmetic_derivative(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 { return -1 }
		n := input[0]
		if n < 0 || n > max_n { return -1 }
		return ad_from_factors(n)
	}
}
