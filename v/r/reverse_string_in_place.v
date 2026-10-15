module reverse_string_in_place

const max_length = 4096

// Reverse bytes by swapping inward from both ends.
@[export: 'reverse_string_in_place']
pub fn reverse_string_in_place(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	unsafe {
		for index in 0 .. length {
			if input[index] < 0 || input[index] > 255 { return -1 }
		}
		if output_capacity < length || (length != 0 && output == nil) { return -2 }
		for index in 0 .. length { output[index] = u8(input[index]) }
		mut left := usize(0)
		mut right := length
		for left < right {
			right--
			if left >= right { break }
			temporary := output[left]
			output[left] = output[right]
			output[right] = temporary
			left++
		}
		return i64(length)
	}
}
