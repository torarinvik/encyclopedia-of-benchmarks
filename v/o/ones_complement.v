module main

const max_input_length = 64

@[export: 'ones_complement']
pub fn ones_complement(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if length == 0 || length > max_input_length || input == nil { return -1 }
		for i in 0 .. int(length) {
			if input[i] != 48 && input[i] != 49 { return -1 }
		}
		if length > capacity || output == nil { return -2 }
		for i in 0 .. int(length) {
			output[i] = if input[i] == 48 { u8(49) } else { u8(48) }
		}
		return i64(length)
	}
}
