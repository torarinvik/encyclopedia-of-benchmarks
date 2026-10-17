module shuffled_shift_cipher

const max_passcode_length = 20
const max_text_length = 256
const max_parseable_input_length = 279
const alphabet_length = 97

fn is_ascii_alphanumeric(value i64) bool {
	return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@[export: 'shuffled_shift_cipher']
pub fn shuffled_shift_cipher(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_parseable_input_length) { return -1 }
		pass_length_value, text_length_value := input[0], input[1]
		if pass_length_value < 1 || pass_length_value > max_passcode_length || text_length_value < 0 || text_length_value > max_text_length { return -1 }
		pass_length, text_length := int(pass_length_value), int(text_length_value)
		if input_length != usize(2 + pass_length + text_length) { return -1 }

		mut passcode := [max_passcode_length]u8{}
		for index in 0 .. pass_length {
			value := input[index + 2]
			if !is_ascii_alphanumeric(value) { return -1 }
			passcode[index] = u8(value)
		}
		text_start := 2 + pass_length
		mut plaintext := [max_text_length]u8{}
		for index in 0 .. text_length {
			value := input[text_start + index]
			if !((value >= 32 && value <= 126) || value == 9 || value == 10) { return -1 }
			plaintext[index] = u8(value)
		}
		if output == nil || output_capacity < usize(text_length) { return -2 }

		mut breakpoints := []bool{len: 128, init: false}
		mut shift_sum := i64(0)
		for index in 0 .. pass_length {
			byte := passcode[index]
			breakpoints[int(byte)] = true
			if index % 2 == 0 { shift_sum += i64(byte) } else { shift_sum -= i64(byte) }
		}
		shift := if shift_sum > 0 { int(shift_sum) } else { pass_length }

		mut alphabet := [alphabet_length]u8{}
		mut alphabet_len := 0
		for value in 97 .. 123 { alphabet[alphabet_len] = u8(value); alphabet_len++ }
		for value in 65 .. 91 { alphabet[alphabet_len] = u8(value); alphabet_len++ }
		for value in 48 .. 58 { alphabet[alphabet_len] = u8(value); alphabet_len++ }
		for value in 33 .. 127 {
			if !is_ascii_alphanumeric(i64(value)) { alphabet[alphabet_len] = u8(value); alphabet_len++ }
		}
		alphabet[alphabet_len] = 32; alphabet_len++
		alphabet[alphabet_len] = 9; alphabet_len++
		alphabet[alphabet_len] = 10; alphabet_len++

		mut key := [alphabet_length]u8{}
		mut segment := [alphabet_length]u8{}
		mut key_len, mut segment_len := 0, 0
		for index in 0 .. alphabet_len {
			byte := alphabet[index]
			segment[segment_len] = byte
			segment_len++
			if breakpoints[int(byte)] || index + 1 == alphabet_len {
				for segment_len > 0 {
					segment_len--
					key[key_len] = segment[segment_len]
					key_len++
				}
			}
		}

		for index in 0 .. text_length {
			mut key_index := 0
			for key_index < key_len && key[key_index] != plaintext[index] { key_index++ }
			output[index] = key[(key_index + shift) % alphabet_length]
		}
		return i64(text_length)
	}
}
