module how_many_times_rotated

const max_array_length = usize(256)
const max_input_length = max_array_length + 1

@[export: 'how_many_times_rotated']
pub fn how_many_times_rotated(input &i64, length usize) i64 {
	if length > max_input_length { return -1 }
	if length > max_array_length { return -1 }
	if length == 0 { return 0 }
	if unsafe { input == nil } { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			if input[index] < -2147483648 || input[index] > 2147483647 { return -1 }
		}

		mut low := 0
		mut high := int(length)
		if high > 0 { high-- }
		for low < high {
			middle := low + (high - low) / 2
			if input[middle] > input[high] { low = middle + 1 }
			else { high = middle }
		}
		return i64(low)
	}
}
