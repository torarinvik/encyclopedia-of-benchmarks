module shootout_strcat

const max_append_count = i64(4096)
const max_text_bytes = 24576

@[export: 'shootout_strcat']
pub fn shootout_strcat(append_count i64, mut output &u8, output_capacity usize) i64 {
	if append_count < 0 || append_count > max_append_count {
		return -1
	}

	mut text := [max_text_bytes + 1]u8{}
	mut length := 0
	mut buffer_capacity := 32
	for _ in 0 .. int(append_count) {
		if buffer_capacity - length < 7 {
			buffer_capacity *= 2
		}
		text[length] = 104
		text[length + 1] = 101
		text[length + 2] = 108
		text[length + 3] = 108
		text[length + 4] = 111
		text[length + 5] = 10
		length += 6
		text[length] = 0
	}

	mut staged := [6]u8{}
	mut reversed_digits := [5]u8{}
	mut digit_count := 0
	mut value := length
	for {
		reversed_digits[digit_count] = u8(48 + value % 10)
		digit_count++
		value /= 10
		if value == 0 {
			break
		}
	}
	mut used := 0
	for digit_count > 0 {
		digit_count--
		staged[used] = reversed_digits[digit_count]
		used++
	}
	staged[used] = 10
	used++

	if unsafe { output == nil } || output_capacity < used {
		return -2
	}
	unsafe {
		for index in 0 .. used {
			output[index] = staged[index]
		}
	}
	return i64(used)
}
