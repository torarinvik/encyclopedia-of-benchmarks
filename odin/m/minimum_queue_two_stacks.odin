package minimum_queue_two_stacks

import "core:c"

QUEUE_CAPACITY :: 16
MAX_PARSEABLE_LENGTH :: 65
VALUE_MIN :: i64(-1000)
VALUE_MAX :: i64(1000)
CHECKSUM_OFFSET :: i64(1001)

@(export)
minimum_queue_two_stacks :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < 0 || input[0] > 32 do return -1

	var in_values: [QUEUE_CAPACITY]i64
	var in_minimums: [QUEUE_CAPACITY]i64
	var out_values: [QUEUE_CAPACITY]i64
	var out_minimums: [QUEUE_CAPACITY]i64
	in_count := 0
	out_count := 0
	cursor := 1
	operation_count := int(input[0])
	checksum: i64 = 0

	for operation in 0..<operation_count {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		if opcode == 0 {
			if cursor >= int(length) do return -1
			value := input[cursor]
			cursor += 1
			if value < VALUE_MIN || value > VALUE_MAX || in_count + out_count >= QUEUE_CAPACITY do return -1
			in_values[in_count] = value
			if in_count == 0 || value < in_minimums[in_count - 1] {
				in_minimums[in_count] = value
			} else {
				in_minimums[in_count] = in_minimums[in_count - 1]
			}
			in_count += 1
		} else if opcode == 1 {
			if in_count + out_count == 0 do return -1
			if out_count == 0 {
				for in_count > 0 {
					in_count -= 1
					value := in_values[in_count]
					out_values[out_count] = value
					if out_count == 0 || value < out_minimums[out_count - 1] {
						out_minimums[out_count] = value
					} else {
						out_minimums[out_count] = out_minimums[out_count - 1]
					}
					out_count += 1
				}
			}
			out_count -= 1
			checksum += i64(operation + 1) * (out_values[out_count] + CHECKSUM_OFFSET)
		} else if opcode == 2 {
			if in_count + out_count == 0 do return -1
			observed: i64
			if in_count == 0 {
				observed = out_minimums[out_count - 1]
			} else if out_count == 0 {
				observed = in_minimums[in_count - 1]
			} else if in_minimums[in_count - 1] < out_minimums[out_count - 1] {
				observed = in_minimums[in_count - 1]
			} else {
				observed = out_minimums[out_count - 1]
			}
			checksum += i64(operation + 1) * (observed + CHECKSUM_OFFSET)
		} else do return -1
	}
	if cursor != int(length) do return -1

	position := 0
	for index in 0..<out_count {
		position += 1
		checksum += i64(position) * (out_values[out_count - index - 1] + CHECKSUM_OFFSET)
	}
	for index in 0..<in_count {
		position += 1
		checksum += i64(position) * (in_values[index] + CHECKSUM_OFFSET)
	}
	return checksum
}
