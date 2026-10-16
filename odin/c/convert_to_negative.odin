package convert_to_negative

import "core:c"

@(export)
convert_to_negative :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 4096 do return -1
	count := values[0]
	if count < 0 || count > 4095 || c.size_t(count) != length - 1 do return -1
	for index in 0..<int(count) {
		if values[index + 1] < 0 || values[index + 1] > 255 do return -1
	}
	if c.size_t(count) > output_capacity || (count != 0 && output == nil) do return -2
	for index in 0..<int(count) { output[index] = u8(255 - values[index + 1]) }
	return count
}
