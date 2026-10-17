module euler_problem_7

const sieve_limit = 1_000_000
const max_ordinal = i64(10_001)
const max_valid_input_length = 1
const max_parseable_input_length = 2

@[export: 'euler_problem_7']
pub fn euler_problem_7(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < max_valid_input_length || length > max_parseable_input_length {
		return -1
	}
	unsafe {
		if length != max_valid_input_length || input[0] < 1 || input[0] > max_ordinal { return -1 }
		mut composite := []bool{len: sieve_limit}
		mut count := i64(0)
		for candidate in 2 .. sieve_limit {
			if !composite[candidate] {
				count++
				if count == input[0] { return i64(candidate) }
				mut multiple := candidate * 2
				for multiple < sieve_limit {
					composite[multiple] = true
					multiple += candidate
				}
			}
		}
		return -1
	}
}
