package alternative_list_arrange

import "core:c"

MAX_SIDE :: 64

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
alternative_list_arrange :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	if input[0] < 0 || input[0] > MAX_SIDE do return -1
	a := int(input[0])
	if c.size_t(1 + a) >= length || input[1 + a] < 0 || input[1 + a] > MAX_SIDE do return -1
	b := int(input[1 + a])
	if length != c.size_t(2 + a + b) do return -1
	count := a + b
	if count == 0 do return 0
	if output == nil || output_capacity < c.size_t(count * 8) do return -2
	written := 0
	for i := 0; i < max(a, b); i += 1 {
		if i < a {
			store_i64_le(output, written * 8, input[1 + i])
			written += 1
		}
		if i < b {
			store_i64_le(output, written * 8, input[2 + a + i])
			written += 1
		}
	}
	return i64(count)
}
