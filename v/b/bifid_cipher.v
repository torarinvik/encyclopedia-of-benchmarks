module bifid_cipher

fn letter_index(value i64, merge_j bool) i64 {
	mut normalized := value
	if normalized >= 97 && normalized <= 122 { normalized -= 32 }
	if normalized < 65 || normalized > 90 { return -1 }
	mut index := normalized - 65
	if index == 9 {
		if !merge_j { return -1 }
		index = 8
	} else if index > 9 {
		index--
	}
	return index
}

fn letter_for_index(index usize) u8 {
	mut value := usize(97) + index
	if index >= 9 { value++ }
	return u8(value)
}

// Fractionate a fixed-square Bifid cipher over one complete message block.
@[export: 'bifid_cipher']
pub fn bifid_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 258 { return -1 }
	mode := unsafe { input[0] }
	text_length_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 256 {
		return -1
	}
	text_length := usize(text_length_value)
	if length != text_length + 2 { return -1 }

	mut rows := [256]u8{}
	mut columns := [256]u8{}
	mut coordinates := [512]u8{}
	mut result := [256]u8{}
	mut result_length := usize(0)

	if mode == 0 {
		for i := usize(0); i < text_length; i++ {
			value := unsafe { input[i + 2] }
			if value == 32 { continue }
			index := letter_index(value, true)
			if index < 0 { return -1 }
			rows[result_length] = u8(index / 5 + 1)
			columns[result_length] = u8(index % 5 + 1)
			result_length++
		}
		for i := usize(0); i < result_length; i++ {
			coordinates[i] = rows[i]
			coordinates[result_length + i] = columns[i]
		}
		for i := usize(0); i < result_length; i++ {
			row := usize(coordinates[2 * i] - 1)
			column := usize(coordinates[2 * i + 1] - 1)
			result[i] = letter_for_index(row * 5 + column)
		}
	} else {
		result_length = text_length
		for i := usize(0); i < text_length; i++ {
			value := unsafe { input[i + 2] }
			index := letter_index(value, false)
			if index < 0 { return -1 }
			coordinates[2 * i] = u8(index / 5 + 1)
			coordinates[2 * i + 1] = u8(index % 5 + 1)
		}
		for i := usize(0); i < result_length; i++ {
			row := usize(coordinates[i] - 1)
			column := usize(coordinates[result_length + i] - 1)
			result[i] = letter_for_index(row * 5 + column)
		}
	}

	if output_capacity < result_length { return -2 }
	for i := usize(0); i < result_length; i++ {
		unsafe { output[i] = result[i] }
	}
	return i64(result_length)
}
