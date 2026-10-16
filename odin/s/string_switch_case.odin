package string_switch_case

import "core:c"

MAX_TEXT_LENGTH :: 1024
MAX_INPUT_LENGTH :: 1027

is_space :: proc(value: i64) -> bool {
	return value == 32 || (value >= 9 && value <= 13) || (value >= 28 && value <= 31)
}

is_word :: proc(value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
		(value >= 48 && value <= 57)
}

@(export)
string_switch_case :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	mode, separator, text_length := input[0], input[1], input[2]
	if mode < 0 || mode > 8 || separator < 0 || separator > 127 || text_length < 0 ||
		text_length > MAX_TEXT_LENGTH || length != c.size_t(text_length) + 3 ||
		((mode != 3 && mode != 4) && separator != 0) do return -1
	for i := 0; i < int(text_length); i += 1 {
		if input[i + 3] < 0 || input[i + 3] > 127 do return -1
	}
	result: [MAX_TEXT_LENGTH]u8
	used: usize = 0
	if mode <= 2 {
		at_word_start := true
		for i := 0; i < int(text_length); i += 1 {
			value := input[i + 3]
			if !is_word(value) { at_word_start = true; continue }
			if at_word_start {
				if value >= 97 && value <= 122 do value -= 32
				at_word_start = false
			} else if value >= 65 && value <= 90 do value += 32
			result[used] = u8(value)
			used += 1
		}
		if mode == 2 {
			if used == 0 {
				message := [16]u8{'n','o','t',' ','v','a','l','i','d',' ','s','t','r','i','n','g'}
				for i := 0; i < 16; i += 1 { result[used] = message[i]; used += 1 }
			} else if result[0] >= 'A' && result[0] <= 'Z' do result[0] += 32
		}
	} else {
		upper := mode == 4 || mode == 6 || mode == 8
		delimiter := u8(separator)
		if mode > 4 && mode <= 6 do delimiter = '_'
		if mode > 6 do delimiter = '-'
		group_has_word, pending_space := false, false
		for i := 0; i < int(text_length); i += 1 {
			value := input[i + 3]
			if is_space(value) { if group_has_word do pending_space = true; continue }
			if !is_word(value) { group_has_word = false; pending_space = false; continue }
			if pending_space && group_has_word { result[used] = delimiter; used += 1 }
			pending_space = false
			if upper && value >= 97 && value <= 122 do value -= 32
			else if !upper && value >= 65 && value <= 90 do value += 32
			result[used] = u8(value)
			used += 1
			group_has_word = true
		}
	}
	if used > capacity || (used > 0 && output == nil) do return -2
	for i: usize = 0; i < used; i += 1 { output[i] = result[i] }
	return i64(used)
}
