module unique_letters_count

const max_text_length = 256
const max_input_length = max_text_length + 1
const letter_count = 26
const bytes_per_record = 8

fn store_i32_le(mut output &u8, position int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'unique_letters_count']
pub fn unique_letters_count(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	text_length_value := unsafe { input[0] }
	if text_length_value < 0 || text_length_value > max_text_length { return -1 }
	text_length := int(text_length_value)
	if text_length + 1 != int(length) { return -1 }

	for index := 0; index < text_length; index++ {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 127 { return -1 }
	}

	mut frequencies := [26]i64{}
	mut first_seen := [26]i64{}
	mut unique_count := 0
	for index := 0; index < text_length; index++ {
		mut value := unsafe { input[index + 1] }
		if value >= 65 && value <= 90 {
			value += 32
		} else if value < 97 || value > 122 {
			continue
		}
		letter_index := int(value - 97)
		if frequencies[letter_index] == 0 {
			first_seen[unique_count] = value
			unique_count++
		}
		frequencies[letter_index]++
	}

	mut maximum_result := text_length
	if maximum_result > letter_count {
		maximum_result = letter_count
	}
	required_capacity := maximum_result * bytes_per_record
	if output_capacity < required_capacity || (required_capacity > 0 && unsafe { output == nil }) { return -2 }
	for index := 0; index < unique_count; index++ {
		letter := first_seen[index]
		store_i32_le(mut output, index * bytes_per_record, letter)
		store_i32_le(mut output, index * bytes_per_record + 4, frequencies[int(letter - 97)])
	}
	return i64(unique_count)
}
