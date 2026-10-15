package format_phone_number

import "core:c"

@(export)
format_phone_number :: proc "c" (values: [^]i64, length: c.size_t,
								  output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 10 do return -1
	for i := c.size_t(0); i < 10; i += 1 {
		if values[i] < 48 || values[i] > 57 do return -1
	}
	if output == nil || output_capacity < 14 do return -2

	output[0] = 40
	for i := c.size_t(0); i < 3; i += 1 do output[i + 1] = u8(values[i])
	output[4] = 41
	output[5] = 32
	for i := c.size_t(0); i < 3; i += 1 do output[i + 6] = u8(values[i + 3])
	output[9] = 45
	for i := c.size_t(0); i < 4; i += 1 do output[i + 10] = u8(values[i + 6])
	return 14
}
