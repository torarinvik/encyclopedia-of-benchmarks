package scan_scheduling

import "core:c"

MAX_REQUESTS :: 64
MAX_OUTPUT_VALUES :: 65

sort_ascending :: proc(values: [^]i32, count: int) {
	for i := 1; i < count; i += 1 {
		value := values[i]
		position := i
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position -= 1
		}
		values[position] = value
	}
}

put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(8 * byte))
	}
}

@(export)
scan_scheduling :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 68 do return -1
	disk_size, head, direction, request_count := input[0], input[1], input[2], input[3]
	if disk_size < 1 || disk_size > 256 || head < 0 || head >= disk_size do return -1
	if (direction != 0 && direction != 1) || request_count < 0 || request_count > MAX_REQUESTS do return -1
	if length != c.size_t(4 + request_count) do return -1

	left: [MAX_REQUESTS]i32 = {}
	right: [MAX_REQUESTS]i32 = {}
	left_count, right_count := 0, 0
	for i in 0..<int(request_count) {
		request := input[4 + i]
		if request < 0 || request >= disk_size do return -1
		if request < head {
			left[left_count] = request
			left_count += 1
		} else {
			right[right_count] = request
			right_count += 1
		}
	}
	sort_ascending(raw_data(left[:]), left_count)
	sort_ascending(raw_data(right[:]), right_count)

	ordered: [MAX_OUTPUT_VALUES]i32 = {}
	count := 0
	if request_count > 0 {
		if direction == 1 {
			for i in 0..<right_count { ordered[count] = right[i]; count += 1 }
			ordered[count] = disk_size - 1
			count += 1
			for i := left_count; i > 0; i -= 1 { ordered[count] = left[i - 1]; count += 1 }
		} else {
			for i := left_count; i > 0; i -= 1 { ordered[count] = left[i - 1]; count += 1 }
			ordered[count] = 0
			count += 1
			for i in 0..<right_count { ordered[count] = right[i]; count += 1 }
		}
	}
	bytes := count * 4
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i in 0..<count { put_i32_le(output, i * 4, ordered[i]) }
	return i64(bytes)
}
