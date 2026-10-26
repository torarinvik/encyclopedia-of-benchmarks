package parameterized_pattern_matching

import "core:c"

MAX_TEXT :: 24
MAX_PATTERN :: 8
MAX_INPUT :: 34
MAX_OUTPUT_BYTES :: 200
ALPHABET :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

predecessor_code :: proc(input: [^]i64, offset, count: int, code: []i64) {
	last: [ALPHABET]i64
	for symbol := 0; symbol < ALPHABET; symbol += 1 { last[symbol] = -1 }
	for index := 0; index < count; index += 1 {
		symbol := int(input[offset + index])
		code[index] = 0
		if last[symbol] >= 0 { code[index] = i64(index) - last[symbol] }
		last[symbol] = i64(index)
	}
}

@(export)
parameterized_pattern_matching :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	text_length_value, pattern_length_value := input[0], input[1]
	if text_length_value < 0 || text_length_value > MAX_TEXT ||
		pattern_length_value < 1 || pattern_length_value > MAX_PATTERN do return -1
	text_length, pattern_length := int(text_length_value), int(pattern_length_value)
	if length != c.size_t(2 + text_length + pattern_length) do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 0 || input[index] >= ALPHABET do return -1
	}

	pattern_code: [MAX_PATTERN]i64
	predecessor_code(input, 2 + text_length, pattern_length, pattern_code[:])
	matches: [MAX_TEXT]int
	match_count := 0
	if pattern_length <= text_length {
		for start := 0; start <= text_length-pattern_length; start += 1 {
			window_code: [MAX_PATTERN]i64
			predecessor_code(input, 2 + start, pattern_length, window_code[:])
			same := true
			for index := 0; index < pattern_length; index += 1 {
				if pattern_code[index] != window_code[index] { same = false }
			}
			if same { matches[match_count] = start; match_count += 1 }
		}
	}

	output_bytes := 8 * (match_count + 1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	store_i64_le(&staged[0], 0, i64(match_count))
	for index := 0; index < match_count; index += 1 {
		store_i64_le(&staged[0], 8*(index+1), i64(matches[index]))
	}
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
