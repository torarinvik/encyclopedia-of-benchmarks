module comparison

const max_string_length = 64
const max_input_length = 3 + 2 * max_string_length

fn fold_ascii(value i64, mode i64) i64 {
	if mode == 1 && value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'comparison']
pub fn comparison(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return -2 }
	mode := unsafe { values[0] }
	first_length_value := unsafe { values[1] }
	if (mode != 0 && mode != 1) || first_length_value < 0 || first_length_value > max_string_length { return -2 }
	first_length := int(first_length_value)
	second_length_position := 2 + first_length
	if second_length_position >= int(length) { return -2 }
	second_length_value := unsafe { values[second_length_position] }
	if second_length_value < 0 || second_length_value > max_string_length { return -2 }
	second_length := int(second_length_value)
	second_start := second_length_position + 1
	if second_start + second_length != int(length) { return -2 }

	for index in 0 .. first_length {
		value := unsafe { values[2 + index] }
		if value < 1 || value > 127 { return -2 }
	}
	for index in 0 .. second_length {
		value := unsafe { values[second_start + index] }
		if value < 1 || value > 127 { return -2 }
	}

	common_length := if first_length < second_length { first_length } else { second_length }
	for index in 0 .. common_length {
		left := fold_ascii(unsafe { values[2 + index] }, mode)
		right := fold_ascii(unsafe { values[second_start + index] }, mode)
		if left < right { return -1 }
		if left > right { return 1 }
	}
	if first_length < second_length { return -1 }
	if first_length > second_length { return 1 }
	return 0
}
