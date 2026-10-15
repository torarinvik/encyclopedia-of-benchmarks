package convert_number_to_words

import "core:c"

word :: proc(id: int) -> string {
	switch id {
	case 0: return "zero"
	case 1: return "one"
	case 2: return "two"
	case 3: return "three"
	case 4: return "four"
	case 5: return "five"
	case 6: return "six"
	case 7: return "seven"
	case 8: return "eight"
	case 9: return "nine"
	case 10: return "ten"
	case 11: return "eleven"
	case 12: return "twelve"
	case 13: return "thirteen"
	case 14: return "fourteen"
	case 15: return "fifteen"
	case 16: return "sixteen"
	case 17: return "seventeen"
	case 18: return "eighteen"
	case 19: return "nineteen"
	case 20: return "twenty"
	case 21: return "thirty"
	case 22: return "forty"
	case 23: return "fifty"
	case 24: return "sixty"
	case 25: return "seventy"
	case 26: return "eighty"
	case 27: return "ninety"
	case 28: return "quadrillion"
	case 29: return "trillion"
	case 30: return "billion"
	case 31: return "million"
	case 32: return "thousand"
	case 33: return "hundred"
	case 34: return "billiard"
	case 35: return "milliard"
	case 36: return "crore crore"
	case 37: return "lakh crore"
	case 38: return "crore"
	case 39: return "lakh"
	case 40: return "negative"
	}
	return ""
}

append_word :: proc(output: []u8, length: int, id: int, separate: bool) -> int {
	if separate && length > 0 { output[length] = ' '; length += 1 }
	text := word(id)
	for i in 0..<len(text) { output[length + i] = text[i] }
	return length + len(text)
}
append_small :: proc(n: u64, output: []u8, length: int) -> int {
	if n < 10 { return append_word(output, length, int(n), true) }
	if n < 20 { return append_word(output, length, int(n) + 10, true) }
	length = append_word(output, length, int(n / 10) + 18, true)
	if n % 10 != 0 { output[length] = '-'; length += 1; length = append_word(output, length, int(n % 10), false) }
	return length
}
scale_count :: proc(system: int) -> int { if system == 1 { return 5 }; return 6 }
scale_power :: proc(system, index: int) -> u64 {
	if system == 0 { return [6]u64{1_000_000_000_000_000,1_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index] }
	if system == 1 { return [5]u64{1_000_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index] }
	return [6]u64{100_000_000_000_000,1_000_000_000_000,10_000_000,100_000,1_000,100}[index]
}
scale_word :: proc(system, index: int) -> int {
	if system == 0 { return [6]int{28,29,30,31,32,33}[index] }
	if system == 1 { return [5]int{34,35,31,32,33}[index] }
	return [6]int{36,37,38,39,32,33}[index]
}
append_number :: proc(n_input: u64, system: int, output: []u8, length: int, depth: int) -> int {
	if depth > 8 { return length }
	n := n_input
	initial_length := length
	for i := 0; i < scale_count(system); i += 1 {
		power := scale_power(system, i)
		group := n / power
		n %= power
		if group == 0 { continue }
		if group >= 100 { length = append_number(group, system, output, length, depth + 1) }
		else { length = append_small(group, output, length) }
		length = append_word(output, length, scale_word(system, i), true)
	}
	if n > 0 || length == initial_length { length = append_small(n, output, length) }
	return length
}

@(export)
convert_number_to_words :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 || input[1] < 0 || input[1] > 2 do return -1
	system := int(input[1]); number := input[0]
	limit: i64 = 9_000_000_000_000_000_000
	if system == 0 { limit = 999_999_999_999_999_999 }
	if number < -limit || number > limit do return -1
	magnitude := u64(if number < 0 { -number } else { number })
	words: [512]u8
	word_count := 0
	if number < 0 { word_count = append_word(words[:], word_count, 40, true) }
	word_count = append_number(magnitude, system, words[:], word_count, 0)
	if capacity < c.size_t(word_count) || output == nil do return -2
	for i := 0; i < word_count; i += 1 { output[i] = words[i] }
	return i64(word_count)
}
