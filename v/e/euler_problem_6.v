module euler_problem_6

const max_parseable_input_length = 2

@[export: 'euler_problem_6']
pub fn euler_problem_6(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 100 || length != 1 { return -1 }
		n := input[0]
		mut sum := i64(0)
		mut sum_of_squares := i64(0)
		for value := i64(1); value <= n; value++ {
			sum += value
			sum_of_squares += value * value
		}
		return sum * sum - sum_of_squares
	}
}
