module polynomial_evaluation_direct

const invalid_result = i64(-9223372036854775807 - 1)

fn integer_power(base i64, exponent int) i64 {
	mut result := i64(1)
	for _ in 0 .. exponent { result *= base }
	return result
}

// Bounded integer port of the pinned direct-power polynomial routine.
@[export: 'polynomial_evaluation_direct']
pub fn polynomial_evaluation_direct(values &i64, length usize) i64 {
	if length < 2 || length > 10 { return invalid_result }
	count := unsafe { values[0] }
	x := unsafe { values[1] }
	if count < 0 || count > 8 || length != usize(count + 2) { return invalid_result }
	if x < -10 || x > 10 { return invalid_result }
	for index in 0 .. int(count) {
		coefficient := unsafe { values[index + 2] }
		if coefficient < -1000 || coefficient > 1000 { return invalid_result }
	}
	mut result := i64(0)
	for index in 0 .. int(count) {
		result += unsafe { values[index + 2] } * integer_power(x, index)
	}
	return result
}
