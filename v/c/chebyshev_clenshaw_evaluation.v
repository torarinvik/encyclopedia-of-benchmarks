// Clenshaw's backward recurrence for Chebyshev coefficients over a prime field.
module chebyshev_clenshaw_evaluation

const modulus = i64(998244353)
const max_degree = 16
const max_parseable_length = 21

fn reduce_field(value i64) i64 {
	mut reduced := value % modulus
	if reduced < 0 { reduced += modulus }
	return reduced
}

@[export: 'chebyshev_clenshaw_evaluation']
pub fn chebyshev_clenshaw_evaluation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_length { return -1 }
		degree_value := input[0]
		if degree_value < 0 || degree_value > max_degree { return -1 }
		degree := int(degree_value)
		if int(length) != degree + 3 { return -1 }
		x := input[1]
		if x < 0 || x >= modulus { return -1 }
		for i := 0; i <= degree; i++ {
			if input[2 + i] < 0 || input[2 + i] >= modulus { return -1 }
		}

		twice_x := 2 * x % modulus
		mut next_one := i64(0)
		mut next_two := i64(0)
		mut k := degree
		for k > 0 {
			current := reduce_field(input[2 + k] + twice_x * next_one - next_two)
			next_two = next_one
			next_one = current
			k--
		}
		return reduce_field(input[2] + x * next_one - next_two)
	}
}
