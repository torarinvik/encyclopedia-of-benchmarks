package integer_to_english

import "core:c"

small_word :: proc(value: i64) -> string {
	switch value {
	case 1: return "One"
	case 2: return "Two"
	case 3: return "Three"
	case 4: return "Four"
	case 5: return "Five"
	case 6: return "Six"
	case 7: return "Seven"
	case 8: return "Eight"
	case 9: return "Nine"
	case 10: return "Ten"
	case 11: return "Eleven"
	case 12: return "Twelve"
	case 13: return "Thirteen"
	case 14: return "Fourteen"
	case 15: return "Fifteen"
	case 16: return "Sixteen"
	case 17: return "Seventeen"
	case 18: return "Eighteen"
	case 19: return "Nineteen"
	case 20: return "Twenty"
	}
	return ""
}

tens_word :: proc(value: i64) -> string {
	switch value {
	case 2: return "Twenty"
	case 3: return "Thirty"
	case 4: return "Forty"
	case 5: return "Fifty"
	case 6: return "Sixty"
	case 7: return "Seventy"
	case 8: return "Eighty"
	case 9: return "Ninety"
	}
	return ""
}

append_text :: proc(buffer: [^]u8, position_input: int, text: string) -> int {
	position := position_input
	for index := 0; index < len(text); index += 1 {
		buffer[position] = text[index]
		position += 1
	}
	return position
}

append_word :: proc(buffer: [^]u8, position_input: int, text: string) -> int {
	position := position_input
	if position != 0 {
		buffer[position] = 32
		position += 1
	}
	return append_text(buffer, position, text)
}

append_small :: proc(buffer: [^]u8, position: int, value: i64) -> int {
	word := small_word(value)
	if len(word) == 0 do return position
	return append_word(buffer, position, word)
}

append_group :: proc(buffer: [^]u8, position_input: int, value_input: i64) -> int {
	position := position_input
	value := value_input
	if value >= 100 {
		position = append_small(buffer, position, value / 100)
		position = append_word(buffer, position, "Hundred")
		value %= 100
	}
	if value <= 20 {
		return append_small(buffer, position, value)
	}
	position = append_word(buffer, position, tens_word(value / 10))
	if value % 10 != 0 do position = append_small(buffer, position, value % 10)
	return position
}

append_scale :: proc(buffer: [^]u8, position: int, scale: int) -> int {
	switch scale {
	case 1: return append_word(buffer, position, "Thousand")
	case 2: return append_word(buffer, position, "Million")
	case 3: return append_word(buffer, position, "Billion")
	}
	return position
}

@(export)
integer_to_english :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	value := input[0]
	if value < -2_147_483_648 || value > 2_147_483_647 do return -1
	var buffer: [128]u8
	position := 0
	if value == 0 {
		position = append_word(&buffer[0], position, "Zero")
	} else if value > 0 {
		var groups: [4]i64
		remaining := value
		count := 0
		for remaining != 0 {
			groups[count] = remaining % 1000
			count += 1
			remaining /= 1000
		}
		for count > 0 {
			count -= 1
			if groups[count] != 0 {
				position = append_group(&buffer[0], position, groups[count])
				if count != 0 do position = append_scale(&buffer[0], position, count)
			}
		}
	}
	if position > int(output_capacity) || (position != 0 && output == nil) do return -2
	for index := 0; index < position; index += 1 do output[index] = buffer[index]
	return i64(position)
}
