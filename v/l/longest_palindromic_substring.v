module longest_palindromic_substring

fn is_ascii_alphanumeric(value i64) bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

// Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
@[export: 'longest_palindromic_substring']
pub fn longest_palindromic_substring(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length == 0 || length > 1000 { return -1 }
	for index in 0 .. length {
		if !is_ascii_alphanumeric(unsafe { values[index] }) { return -1 }
	}

	mut best_start := usize(0)
	mut best_length := usize(1)
	for center in 0 .. length {
		mut left := center
		mut right := center
		for left > 0 && right + 1 < length &&
			unsafe { values[left - 1] == values[right + 1] } {
			left--
			right++
		}
		mut candidate_length := right - left + 1
		if candidate_length > best_length {
			best_start = left
			best_length = candidate_length
		}

		left = center
		right = center + 1
		for right < length && unsafe { values[left] == values[right] } {
			candidate_length = right - left + 1
			if candidate_length > best_length {
				best_start = left
				best_length = candidate_length
			}
			if left == 0 || right + 1 == length { break }
			left--
			right++
		}
	}

	if output_capacity < best_length { return -2 }
	for index in 0 .. best_length {
		unsafe { output[index] = u8(values[best_start + index]) }
	}
	return i64(best_length)
}
