package map_reduce

import "core:c"

MAX_INPUT :: 256
MAX_WORDS :: 128
TABLE_SIZE :: 512

is_space_byte :: proc "contextless" (value: i64) -> bool {
	return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32
}

token_hash :: proc "contextless" (input: [^]i64, start, length: int) -> int {
	hash := 0
	for offset := 0; offset < length; offset += 1 {
		hash = (hash * 31 + int(input[start + offset])) % 1_000_003
	}
	return hash
}

token_equal :: proc "contextless" (input: [^]i64, start, length, other_start, other_length: int) -> bool {
	if length != other_length do return false
	for offset := 0; offset < length; offset += 1 {
		if input[start + offset] != input[other_start + offset] do return false
	}
	return true
}

write_count :: proc "contextless" (output: [^]u8, position: ^int, count: int) {
	digits: [3]u8
	digit_count := 0
	remaining := count
	for {
		digits[digit_count] = u8('0' + remaining % 10)
		digit_count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for digit_count > 0 {
		digit_count -= 1
		output[position^] = digits[digit_count]
		position^ += 1
	}
}

@(export)
map_reduce :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_INPUT || (length != 0 && input == nil) do return -1
	n := int(length)
	for index := 0; index < n; index += 1 {
		value := input[index]
		if !is_space_byte(value) && (value < 32 || value > 126) do return -1
	}

	starts: [MAX_WORDS]int
	lengths: [MAX_WORDS]int
	counts: [MAX_WORDS]int
	table: [TABLE_SIZE]int
	unique_count, begin, ending := 0, 0, n
	for begin < ending && input[begin] <= 32 { begin += 1 }
	for ending > begin && input[ending - 1] <= 32 { ending -= 1 }

	if begin == ending {
		starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1
		table[0] = 1
	} else {
		cursor := begin
		for cursor < ending {
			for cursor < ending && is_space_byte(input[cursor]) { cursor += 1 }
			if cursor == ending do break
			start := cursor
			for cursor < ending && !is_space_byte(input[cursor]) { cursor += 1 }
			token_length := cursor - start
			slot := token_hash(input, start, token_length) % TABLE_SIZE
			for table[slot] != 0 {
				item := table[slot] - 1
				if token_equal(input, start, token_length, starts[item], lengths[item]) {
					counts[item] += 1
					break
				}
				slot = (slot + 1) % TABLE_SIZE
			}
			if table[slot] == 0 {
				starts[unique_count] = start; lengths[unique_count] = token_length
				counts[unique_count] = 1; table[slot] = unique_count + 1; unique_count += 1
			}
		}
	}

	required := 0
	for item := 0; item < unique_count; item += 1 {
		digits, value := 1, counts[item]
		for value >= 10 { value /= 10; digits += 1 }
		required += lengths[item] + 2 + digits
		if item != 0 { required += 1 }
	}
	if output == nil || output_capacity < c.size_t(required) do return -2

	written := 0
	for item := 0; item < unique_count; item += 1 {
		if item != 0 { output[written] = ','; written += 1 }
		for offset := 0; offset < lengths[item]; offset += 1 {
			output[written] = u8(input[starts[item] + offset]); written += 1
		}
		output[written] = ':'; written += 1
		output[written] = ' '; written += 1
		write_count(output, &written, counts[item])
	}
	return i64(written)
}
