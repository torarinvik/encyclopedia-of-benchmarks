package move_hash_to_end

import "core:c"

MAX_TEXT_LENGTH :: 256

@(export)
move_hash_to_end :: proc "c" (values: [^]i64, length: c.size_t,
                                output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 258 do return -1
	text_length := values[0]
	if text_length < 0 || text_length > MAX_TEXT_LENGTH || length != c.size_t(text_length + 1) do return -1
	for i := 0; i < int(text_length); i += 1 { if values[i + 1] < 0 || values[i + 1] > 127 do return -1 }
	n := c.size_t(text_length)
	if capacity < n || (n > 0 && output == nil) do return -2
	position := c.size_t(0)
	for i := c.size_t(0); i < n; i += 1 {
		if values[i + 1] != 35 { output[position] = u8(values[i + 1]); position += 1 }
	}
	for position < n { output[position] = u8('#'); position += 1 }
	return i64(n)
}
