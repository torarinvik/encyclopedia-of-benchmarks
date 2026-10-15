module palindrome_partitioning

const max_length = 256

@[export: 'palindrome_partitioning']
pub fn palindrome_partitioning(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_length || unsafe { input == nil } { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			if input[index] < 0 || input[index] > 127 { return -1 }
		}
		if output == nil || output_capacity < 8 { return -2 }

		mut palindrome := [max_length * max_length]bool{}
		mut cuts := [max_length]i64{}
		for end in 0 .. int(length) {
			mut best := i64(end)
			for start in 0 .. end + 1 {
				if input[start] == input[end] &&
					(end - start < 2 || palindrome[(start + 1) * max_length + end - 1]) {
					palindrome[start * max_length + end] = true
					candidate := if start == 0 { i64(0) } else { cuts[start - 1] + 1 }
					if candidate < best { best = candidate }
				}
			}
			cuts[end] = best
		}

		bits := u64(cuts[int(length) - 1])
		for byte in 0 .. 8 {
			output[byte] = u8(bits >> (8 * byte))
		}
	}
	return 1
}
