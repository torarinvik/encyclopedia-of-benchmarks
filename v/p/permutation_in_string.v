module permutation_in_string

const max_string_length = 1024
const max_input_length = 2050

fn adjust_count(mut differences &i64, nonzero i64, letter int, amount i64) i64 {
	mut updated_nonzero := nonzero
	unsafe {
		if differences[letter] == 0 { updated_nonzero++ }
		differences[letter] += amount
		if differences[letter] == 0 { updated_nonzero-- }
	}
	return updated_nonzero
}

// Check for a permutation of one lowercase ASCII string inside another.
@[export: 'permutation_in_string']
pub fn permutation_in_string(input &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	first_length_value := unsafe { input[0] }
	second_length_value := unsafe { input[1] }
	if first_length_value < 0 || first_length_value > max_string_length || second_length_value < 0 || second_length_value > max_string_length { return -1 }
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length { return -1 }
	for index in 2 .. int(length) {
		value := unsafe { input[index] }
		if value < 97 || value > 122 { return -1 }
	}
	if first_length > second_length { return 0 }

	mut differences := [26]i64{init: 0}
	mut nonzero := i64(0)
	for index in 0 .. first_length {
		pattern := unsafe { input[2 + index] }
		window := unsafe { input[2 + first_length + index] }
		nonzero = adjust_count(mut differences[0], nonzero, int(pattern - 97), 1)
		nonzero = adjust_count(mut differences[0], nonzero, int(window - 97), -1)
	}
	if nonzero == 0 { return 1 }
	for start in 0 .. second_length - first_length {
		outgoing := unsafe { input[2 + first_length + start] }
		incoming := unsafe { input[2 + first_length + start + first_length] }
		nonzero = adjust_count(mut differences[0], nonzero, int(outgoing - 97), 1)
		nonzero = adjust_count(mut differences[0], nonzero, int(incoming - 97), -1)
		if nonzero == 0 { return 1 }
	}
	return 0
}
