package alternative_string_arrange

import "core:c"

@(export)
alternative_string_arrange :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 0 || input[0] > 64 do return -1
	first_length := int(input[0])
	if c.size_t(1 + first_length) >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64 do return -1
	second_length := int(input[1 + first_length])
	if length != c.size_t(2 + first_length + second_length) do return -1
	for i := 0; i < first_length; i += 1 { if input[1 + i] < 0 || input[1 + i] > 127 do return -1 }
	for i := 0; i < second_length; i += 1 { if input[2 + first_length + i] < 0 || input[2 + first_length + i] > 127 do return -1 }
	count := first_length + second_length
	if output_capacity < c.size_t(count) || (count != 0 && output == nil) do return -2
	written := 0
	for i := 0; i < max(first_length, second_length); i += 1 {
		if i < first_length { output[written] = u8(input[1 + i]); written += 1 }
		if i < second_length { output[written] = u8(input[2 + first_length + i]); written += 1 }
	}
	return i64(written)
}
