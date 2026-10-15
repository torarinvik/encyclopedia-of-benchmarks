module reverse_only_letters

const max_length = 4096

fn is_ascii_letter(value u8) bool {
	return (value >= u8('A') && value <= u8('Z')) || (value >= u8('a') && value <= u8('z'))
}

@[export: 'reverse_only_letters']
pub fn reverse_only_letters(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	unsafe {
		for index in 0 .. length {
			if input[index] < 32 || input[index] > 126 { return -1 }
		}
		if output_capacity < length || (length != 0 && output == nil) { return -2 }
		for index in 0 .. length { output[index] = u8(input[index]) }
		mut left := usize(0)
		mut right := length
		for left < right {
			if !is_ascii_letter(output[left]) {
				left++
			} else if !is_ascii_letter(output[right - 1]) {
				right--
			} else {
				temporary := output[left]
				output[left] = output[right - 1]
				output[right - 1] = temporary
				left++
				right--
			}
		}
		return i64(length)
	}
}
