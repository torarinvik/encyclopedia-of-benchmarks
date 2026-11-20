module minimum_window_subsequence

@[export: 'minimum_window_subsequence']
pub fn minimum_window_subsequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 258 { return -1 }
		if input[0] < 0 || input[0] > 128 { return -1 }
		search_length := int(input[0])
		pattern_length_index := search_length + 1
		if length <= usize(pattern_length_index) { return -1 }
		pattern_length_value := input[pattern_length_index]
		if pattern_length_value < 1 || pattern_length_value > 128 { return -1 }
		pattern_length := int(pattern_length_value)
		if length != usize(search_length + pattern_length + 2) { return -1 }
		for i in 0 .. search_length {
			if input[i + 1] < 0 || input[i + 1] > 127 { return -1 }
		}
		for j in 0 .. pattern_length {
			if input[search_length + 2 + j] < 0 || input[search_length + 2 + j] > 127 { return -1 }
		}

		mut latest_start := [128]i8{}
		for j in 0 .. pattern_length { latest_start[j] = -1 }
		mut best_start := -1
		mut best_length := search_length + 1
		for end in 0 .. search_length {
			byte := input[end + 1]
			for offset in 0 .. pattern_length {
				pattern_index := pattern_length - 1 - offset
				if byte != input[search_length + 2 + pattern_index] { continue }
				candidate := if pattern_index == 0 { end } else { int(latest_start[pattern_index - 1]) }
				if candidate >= 0 && candidate > int(latest_start[pattern_index]) {
					latest_start[pattern_index] = i8(candidate)
				}
			}
			if byte == input[search_length + 2 + pattern_length - 1] && latest_start[pattern_length - 1] >= 0 {
				start := int(latest_start[pattern_length - 1])
				window_length := end - start + 1
				if window_length < best_length || (window_length == best_length && (best_start < 0 || start < best_start)) {
					best_start = start
					best_length = window_length
				}
			}
		}
		if best_start < 0 { return 0 }
		if best_length > capacity || (best_length > 0 && output == nil) { return -2 }
		for i in 0 .. best_length { output[i] = u8(input[best_start + 1 + i]) }
		return i64(best_length)
	}
}
