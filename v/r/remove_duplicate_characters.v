module main

const max_input_length = 4096

@[export: 'remove_duplicate_characters']
pub fn remove_duplicate_characters(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length + 1 { return -1 }
		if input[0] < 0 || input[0] > max_input_length { return -1 }
		text_length := int(input[0])
		if int(length) != text_length + 1 { return -1 }
		for index in 0 .. text_length {
			if input[index + 1] < 0 || input[index + 1] > 127 { return -1 }
		}

		mut seen := []bool{len: 128, init: false}
		mut output_length := 0
		for index in 0 .. text_length {
			byte := int(input[index + 1])
			if !seen[byte] { seen[byte] = true; output_length++ }
		}
		if usize(output_length) > output_capacity || (output_length > 0 && output == nil) { return -2 }

		for index in 0 .. 128 { seen[index] = false }
		mut written := 0
		for index in 0 .. text_length {
			byte := int(input[index + 1])
			if !seen[byte] {
				seen[byte] = true
				output[written] = u8(byte)
				written++
			}
		}
		return i64(written)
	}
}
