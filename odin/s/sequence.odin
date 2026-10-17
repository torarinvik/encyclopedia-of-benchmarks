package sequence

import "core:c"

MAX_COUNT :: 64
MAX_PARSEABLE_INPUT_LENGTH :: 3
MAX_OUTPUT_BYTES :: 8 * MAX_COUNT

generate_nth_term :: proc(index: i64) -> i64 {
	if index == 0 || index == 1 do return index
	if index % 2 == 0 do return 4 * generate_nth_term(index / 2)
	return 4 * generate_nth_term(index / 2) + 1
}

put_i64_le :: proc "contextless" (value: i64, output: [^]u8, offset: int) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
sequence :: proc "c" (values: [^]i64, length: c.size_t,
						output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if length != 1 || values[0] < -MAX_COUNT || values[0] > MAX_COUNT do return -1
	if values[0] <= 0 do return 0

	count := int(values[0])
	required := count * 8
	if output == nil || output_capacity < c.size_t(required) || required > MAX_OUTPUT_BYTES do return -2
	for index := 0; index < count; index += 1 {
		put_i64_le(generate_nth_term(i64(index)), output, index * 8)
	}
	return i64(required)
}
