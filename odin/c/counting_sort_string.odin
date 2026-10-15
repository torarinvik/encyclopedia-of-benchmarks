package counting_sort_string

import "core:c"

MAX_TEXT_LENGTH :: 4095

@(export)
counting_sort_string :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 4096 do return -1
	count := values[0]
	if count < 0 || count > MAX_TEXT_LENGTH || length != c.size_t(count + 1) do return -1

	frequencies: [256]i64
	for value := 0; value < 256; value += 1 { frequencies[value] = 0 }
	for index := 0; index < int(count); index += 1 {
		value := values[index + 1]
		if value < 33 || value > 126 do return -1
		frequencies[int(value)] += 1
	}
	if output == nil || output_capacity < c.size_t(count) do return -2

	for value := 1; value < 256; value += 1 { frequencies[value] += frequencies[value - 1] }
	for index := int(count); index > 0; index -= 1 {
		value := int(values[index])
		frequencies[value] -= 1
		output[int(frequencies[value])] = u8(value)
	}
	return count
}
