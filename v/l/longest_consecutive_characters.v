@[export: 'longest_consecutive_characters']
pub fn longest_consecutive_characters(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 1 || length > 257 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 1 || count_value > 256 || length != usize(count_value + 1) { return -1 }
	count := int(count_value)
	for index := 0; index < count; index++ {
		value := unsafe { values[index + 1] }
		if value < 0 || value > 127 { return -1 }
	}
	if capacity < 3 || isnil(output) { return -2 }

	mut best_character := unsafe { values[1] }
	mut best_length := 1
	mut current_length := 1
	for index := 1; index < count; index++ {
		current := unsafe { values[index + 1] }
		previous := unsafe { values[index] }
		if current == previous {
			current_length++
			if current_length > best_length {
				best_length = current_length
				best_character = current
			}
		} else {
			current_length = 1
		}
	}
	unsafe {
		output[0] = u8(best_character)
		output[1] = u8(best_length & 255)
		output[2] = u8(best_length >> 8)
	}
	return 3
}
