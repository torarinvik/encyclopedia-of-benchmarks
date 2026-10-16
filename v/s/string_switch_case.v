module main

const max_text_length = 1024
const max_input_length = max_text_length + 3

fn is_space(value i64) bool {
	return value == 32 || (value >= 9 && value <= 13) || (value >= 28 && value <= 31)
}

fn is_word(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
		(value >= 48 && value <= 57)
}

@[export: 'string_switch_case']
pub fn string_switch_case(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		mode := input[0]
	separator := input[1]
	text_length := input[2]
	if mode < 0 || mode > 8 || separator < 0 || separator > 127 || text_length < 0 ||
		text_length > max_text_length || length != usize(text_length) + 3 ||
		((mode != 3 && mode != 4) && separator != 0) { return -1 }
		for i in 0 .. int(text_length) {
			if input[i + 3] < 0 || input[i + 3] > 127 { return -1 }
		}
		mut result := [max_text_length]u8{}
		mut used := 0
		if mode <= 2 {
			mut at_word_start := true
			for i in 0 .. int(text_length) {
				mut value := input[i + 3]
				if !is_word(value) { at_word_start = true; continue }
				if at_word_start {
					if value >= 97 && value <= 122 { value -= 32 }
					at_word_start = false
				} else if value >= 65 && value <= 90 { value += 32 }
				result[used] = u8(value)
				used++
			}
			if mode == 2 {
				if used == 0 {
					message := 'not valid string'.bytes()
					for value in message { result[used] = value; used++ }
				} else if result[0] >= 65 && result[0] <= 90 { result[0] += 32 }
			}
		} else {
			upper := mode == 4 || mode == 6 || mode == 8
			mut delimiter := u8(separator)
			if mode > 4 && mode <= 6 { delimiter = u8('_') }
			else if mode > 6 { delimiter = u8('-') }
			mut group_has_word := false
			mut pending_space := false
			for i in 0 .. int(text_length) {
				mut value := input[i + 3]
				if is_space(value) {
					if group_has_word { pending_space = true }
					continue
				}
				if !is_word(value) { group_has_word = false; pending_space = false; continue }
				if pending_space && group_has_word { result[used] = delimiter; used++ }
				pending_space = false
				if upper && value >= 97 && value <= 122 { value -= 32 }
				else if !upper && value >= 65 && value <= 90 { value += 32 }
				result[used] = u8(value)
				used++
				group_has_word = true
			}
		}
		if used > capacity || (used > 0 && output == nil) { return -2 }
		for i in 0 .. used { output[i] = result[i] }
		return i64(used)
	}
}
