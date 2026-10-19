package shootout_strcat

import "core:c"

MAX_APPEND_COUNT :: 4096
MAX_TEXT_BYTES :: 24576

@(export, link_name="shootout_strcat")
shootout_strcat :: proc "c" (append_count: i64, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
	if append_count < 0 || append_count > i64(MAX_APPEND_COUNT) do return -1

	text: [MAX_TEXT_BYTES + 1]u8
	length := 0
	buffer_capacity := 32
	for append := i64(0); append < append_count; append += 1 {
		if buffer_capacity - length < 7 do buffer_capacity *= 2
		text[length] = 104
		text[length + 1] = 101
		text[length + 2] = 108
		text[length + 3] = 108
		text[length + 4] = 111
		text[length + 5] = 10
		length += 6
		text[length] = 0
	}

	staged: [6]u8
	reversed_digits: [5]u8
	digit_count := 0
	value := length
	for {
		reversed_digits[digit_count] = u8(48 + value % 10)
		digit_count += 1
		value /= 10
		if value == 0 do break
	}
	used := 0
	for digit_count > 0 {
		digit_count -= 1
		staged[used] = reversed_digits[digit_count]
		used += 1
	}
	staged[used] = 10
	used += 1

	if output == nil || output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 do output[index] = staged[index]
	return i64(used)
}
