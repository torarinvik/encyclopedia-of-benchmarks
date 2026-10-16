module main

const max_input_length = 4096

@[export: 'swap_case']
pub fn swap_case(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if length > max_input_length || (length > 0 && input == nil) { return -1 }
		for i in 0 .. int(length) {
			if input[i] < 0 || input[i] > 127 { return -1 }
		}
		if length > capacity || (length > 0 && output == nil) { return -2 }
		for i in 0 .. int(length) {
			mut value := input[i]
			if value >= 65 && value <= 90 { value += 32 }
			else if value >= 97 && value <= 122 { value -= 32 }
			output[i] = u8(value)
		}
		return i64(length)
	}
}
