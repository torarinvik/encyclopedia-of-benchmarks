module shortest_palindrome

@[export: 'shortest_palindrome']
pub fn shortest_palindrome(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if length > 64 { return -1 }
		if length > 0 && input == nil { return -1 }
		for index in 0 .. int(length) {
			if input[index] < 32 || input[index] > 126 { return -1 }
		}
		if length == 0 { return 0 }

		mut suffix := [64]usize{}
		for index in 1 .. int(length) {
			mut matched := suffix[index - 1]
			for matched > 0 && input[matched] != input[index] { matched = suffix[matched - 1] }
			if input[matched] == input[index] { matched++ }
			suffix[index] = matched
		}

		mut prefix_match := usize(0)
		for index in 0 .. int(length) {
			reversed_value := input[int(length) - 1 - index]
			for prefix_match > 0 && reversed_value != input[prefix_match] {
				prefix_match = suffix[prefix_match - 1]
			}
			if reversed_value == input[prefix_match] { prefix_match++ }
		}

		output_length := 2 * length - prefix_match
		if output == nil || output_capacity < output_length { return -2 }
		for index in 0 .. int(length) {
			output[index] = u8(input[int(length) - 1 - index])
		}
		for index in int(prefix_match) .. int(length) {
			output[int(length) + index - int(prefix_match)] = u8(input[index])
		}
		return i64(output_length)
	}
}
