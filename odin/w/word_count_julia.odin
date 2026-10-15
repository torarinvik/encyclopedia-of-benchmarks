package word_count_julia

import "core:c"

Word_Entry :: struct { start, length, count: int }

lower_byte :: proc "contextless" (input: [^]i64, index: int) -> u8 {
	byte := u8(input[index])
	if byte >= 'A' && byte <= 'Z' do return byte + ('a' - 'A')
	return byte
}

is_word_byte :: proc "contextless" (byte: u8) -> bool {
	return (byte >= 'a' && byte <= 'z') || (byte >= '0' && byte <= '9') || byte == '_'
}

compare_word :: proc "contextless" (input: [^]i64, start, length: int, entry: Word_Entry) -> int {
	shared := min(length, entry.length)
	for offset := 0; offset < shared; offset += 1 {
		left := lower_byte(input, start + offset)
		right := lower_byte(input, entry.start + offset)
		if left < right do return -1
		if left > right do return 1
	}
	if length < entry.length do return -1
	if length > entry.length do return 1
	return 0
}

write_count :: proc "contextless" (output: [^]u8, position: ^int, count: int) {
	digits: [4]u8
	digit_count := 0
	remaining := count
	for {
		digits[digit_count] = u8('0' + remaining % 10)
		digit_count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	output[position^] = '='; position^ += 1
	for digit_count > 0 {
		digit_count -= 1
		output[position^] = digits[digit_count]; position^ += 1
	}
	output[position^] = '\n'; position^ += 1
}

@(export)
word_count_julia :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 1000 || (length != 0 && input == nil) do return -1
	n := int(length)
	for index := 0; index < n; index += 1 {
		if input[index] < 0 || input[index] > 127 do return -1
	}
	entries: [1000]Word_Entry
	unique_count, index := 0, 0
	for index < n {
		if !is_word_byte(lower_byte(input, index)) { index += 1; continue }
		start := index
		for index < n && is_word_byte(lower_byte(input, index)) { index += 1 }
		token_length := index - start
		if index + 1 < n && input[index] == '\'' && is_word_byte(lower_byte(input, index + 1)) {
			token_length += 2; index += 2
		}
		position := 0
		for position < unique_count && compare_word(input, start, token_length, entries[position]) > 0 { position += 1 }
		if position < unique_count && compare_word(input, start, token_length, entries[position]) == 0 {
			entries[position].count += 1
		} else {
			for move := unique_count; move > position; move -= 1 { entries[move] = entries[move - 1] }
			entries[position] = {start, token_length, 1}; unique_count += 1
		}
	}
	required := 0
	for item := 0; item < unique_count; item += 1 {
		digits, value := 1, entries[item].count
		for value >= 10 { value /= 10; digits += 1 }
		required += entries[item].length + digits + 2
	}
	if output_capacity < c.size_t(required) || (required != 0 && output == nil) do return -2
	written := 0
	for item := 0; item < unique_count; item += 1 {
		for offset := 0; offset < entries[item].length; offset += 1 {
			output[written] = lower_byte(input, entries[item].start + offset); written += 1
		}
		write_count(output, &written, entries[item].count)
	}
	return i64(written)
}
