module longest_palindromic_substring_dp

const max_input_length = 1000

fn is_ascii_alphanumeric(value i64) bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

// Find the rightmost longest ASCII alphanumeric palindrome with substring DP.
@[export: 'longest_palindromic_substring_dp']
pub fn longest_palindromic_substring_dp(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if values == nil || length == 0 || length > max_input_length { return -1 }
	for index in 0 .. length {
		if !is_ascii_alphanumeric(unsafe { values[index] }) { return -1 }
	}

	mut palindrome := []bool{len: length * length}
	mut best_start := usize(0)
	mut best_length := usize(0)
	for end in 0 .. length {
		for start in 0 .. end + 1 {
			is_palindrome := unsafe {
				values[start] == values[end] &&
					(end - start < 2 || palindrome[(start + 1) * length + end - 1])
			}
			unsafe { palindrome[start * length + end] = is_palindrome }
			candidate_length := end - start + 1
			if is_palindrome && (candidate_length > best_length ||
				(candidate_length == best_length && start > best_start)) {
				best_start = start
				best_length = candidate_length
			}
		}
	}

	if output == nil || output_capacity < best_length { return -2 }
	for index in 0 .. best_length {
		unsafe { output[index] = u8(values[best_start + index]) }
	}
	return i64(best_length)
}
