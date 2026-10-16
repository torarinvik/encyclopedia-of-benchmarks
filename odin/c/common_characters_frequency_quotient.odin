package common_characters_frequency_quotient

import "core:c"

@(export)
common_characters_frequency_quotient :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > 1041 do return -1
	string_count := input[0]
	if string_count < 0 || string_count > 16 do return -1
	counts: [26]i64
	offset: c.size_t = 1
	total: c.size_t = 0
	for string_index: i64 = 0; string_index < string_count; string_index += 1 {
		if offset >= length do return -1
		string_length := input[offset]
		offset += 1
		if string_length < 0 || string_length > 64 || c.size_t(string_length) > length - offset do return -1
		for index: i64 = 0; index < string_length; index += 1 {
			value := input[offset]
			offset += 1
			if value < 97 || value > 122 do return -1
			counts[value - 97] += 1
		}
		total += c.size_t(string_length)
		if total > 512 do return -1
	}
	if offset != length do return -1
	used: c.size_t = 0
	if string_count > 0 {
		for letter in 0..26 {
			used += c.size_t(counts[letter] / string_count)
		}
	}
	if used > capacity || (used > 0 && output == nil) do return -2
	output_offset: c.size_t = 0
	if string_count > 0 {
		for letter in 0..26 {
			copies := counts[letter] / string_count
			for copy: i64 = 0; copy < copies; copy += 1 {
				output[output_offset] = u8(97 + letter)
				output_offset += 1
			}
		}
	}
	return i64(used)
}
