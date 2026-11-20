module binary_divisibility_by_three_dfa

// Decide binary divisibility by three with a three-state streaming DFA.
@[export: 'binary_divisibility_by_three_dfa']
pub fn binary_divisibility_by_three_dfa(input &i64, input_length usize,
	output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > 4098 { return -1 }
		bit_count := input[0]
		if bit_count < 1 || bit_count > 4096 || input_length != usize(bit_count + 1) { return -1 }
		mut remainder := i64(0)
		for index := usize(1); index < input_length; index++ {
			if input[index] != 0 && input[index] != 1 { return -1 }
			remainder = (2 * remainder + input[index]) % 3
		}
		if output == nil || output_capacity < 1 { return -2 }

		output[0] = u8(0)
		if remainder == 0 { output[0] = u8(1) }
	}
	return 1
}
