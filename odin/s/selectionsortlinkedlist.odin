package selectionsortlinkedlist

import "core:c"

MAX_COUNT :: 64
MAX_INPUT_LENGTH :: 66

selection_sort_links :: proc "contextless" (values: [^]i32, next: [^]int, head: ^int) {
	minimum := head^
	current := next[minimum]
	previous := minimum
	sorted_tail := -1
	for next[minimum] != -1 {
		for current != -1 {
			if values[current] < values[minimum] {
				if sorted_tail == -1 {
					if previous == minimum {
						head^ = current
						next[minimum] = next[current]
						next[current] = previous
						minimum = current
						current = next[previous]
					} else {
						head^ = current
						next[previous] = next[current]
						next[current] = minimum
						minimum = current
						current = next[previous]
					}
				} else {
					next[sorted_tail] = current
					next[previous] = next[current]
					next[current] = minimum
					minimum = current
					current = next[previous]
				}
			} else {
				previous = next[previous]
				current = next[current]
			}
		}
		sorted_tail = minimum
		minimum = next[minimum]
		previous = minimum
		current = next[minimum]
	}
}

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
selectionsortlinkedlist :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	raw_count := input[0]
	if raw_count < 1 || raw_count > MAX_COUNT || int(length) != 1 + int(raw_count) do return -1
	count := int(raw_count)
	values: [MAX_COUNT]i32 = {}
	next: [MAX_COUNT]int = {}
	for index := 0; index < count; index += 1 {
		if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 do return -1
		values[index] = i32(input[index + 1])
		next[index] = if index + 1 < count { index + 1 } else { -1 }
	}
	byte_count := 4 * count
	if output == nil || int(output_capacity) < byte_count do return -2

	head := 0
	selection_sort_links(&values[0], &next[0], &head)
	node := head
	for index := 0; index < count; index += 1 {
		write_i32_le(output, 4 * index, values[node])
		node = next[node]
	}
	return i64(byte_count)
}
