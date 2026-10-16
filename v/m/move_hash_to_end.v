module main

const max_text_length = 256
const max_parseable_length = max_text_length + 2
const hash_code = 35

@[export: 'move_hash_to_end']
pub fn move_hash_to_end(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_parseable_length { return -1 }
		text_length := values[0]
		if text_length < 0 || text_length > max_text_length || length != usize(text_length + 1) { return -1 }
		for i in 0 .. usize(text_length) {
			if values[i + 1] < 0 || values[i + 1] > 127 { return -1 }
		}
		if capacity < usize(text_length) || (text_length > 0 && output == nil) { return -2 }
		mut position := usize(0)
		for i in 0 .. usize(text_length) {
			value := values[i + 1]
			if value != hash_code {
				output[position] = u8(value)
				position++
			}
		}
		for position < usize(text_length) {
			output[position] = u8(hash_code)
			position++
		}
		return text_length
	}
}
