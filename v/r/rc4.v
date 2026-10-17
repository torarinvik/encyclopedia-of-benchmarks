const max_key_length = 256
const max_plaintext_length = 256
const max_input_values = usize(515)

@[export: 'rc4']
pub fn rc4(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		key_length_value := input[0]
		plaintext_length_value := input[1]
		if key_length_value < 1 || key_length_value > i64(max_key_length) { return -1 }
		if plaintext_length_value < 0 || plaintext_length_value > i64(max_plaintext_length) { return -1 }
		key_length := int(key_length_value)
		plaintext_length := int(plaintext_length_value)
		if length != usize(2 + key_length + plaintext_length) { return -1 }
		for index in 0 .. key_length + plaintext_length {
			value := input[2 + index]
			if value < 0 || value > 255 { return -1 }
		}
		if plaintext_length == 0 { return 0 }
		if output == nil || capacity < usize(plaintext_length) { return -2 }

		mut state := [256]u8{}
		for index in 0 .. 256 { state[index] = u8(index) }
		mut j := 0
		for index in 0 .. 256 {
			j = (j + int(state[index]) + int(input[2 + index % key_length])) % 256
			state[index], state[j] = state[j], state[index]
		}

		mut i := 0
		j = 0
		for offset in 0 .. plaintext_length {
			i = (i + 1) % 256
			j = (j + int(state[i])) % 256
			state[i], state[j] = state[j], state[i]
			stream_index := (int(state[i]) + int(state[j])) % 256
			output[offset] = u8(input[2 + key_length + offset]) ^ state[stream_index]
		}
		return i64(plaintext_length)
	}
}
