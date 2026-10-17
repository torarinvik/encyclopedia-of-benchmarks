package rotate_to_the_right

import "core:c"

MAX_N :: 64
MAX_PARSEABLE_INPUT_LENGTH :: MAX_N + 4
MAX_OUTPUT_BYTES :: MAX_N * 8
MAX_PLACES :: 1_000_000

write_i64_le :: proc "contextless" (buffer: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte in 0..<8 {
		buffer[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
rotate_to_the_right :: proc "c" (input: [^]i64, length: c.size_t,
									 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	n_value := input[0]
	places := input[1]
	if n_value < 1 || n_value > i64(MAX_N) || places < -MAX_PLACES || places > MAX_PLACES do return -1
	n := int(n_value)
	if length != c.size_t(n + 2) do return -1
	for index in 0..<n {
		value := input[2 + index]
		if value < -2147483648 || value > 2147483647 do return -1
	}

	remainder := places % n_value
	shift := int(remainder)
	if remainder < 0 do shift = int(remainder + n_value)
	output_bytes := n * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	encoded: [MAX_OUTPUT_BYTES]u8
	for index in 0..<n {
		source := (index + n - shift) % n
		write_i64_le(&encoded[0], index * 8, input[2 + source])
	}
	for index in 0..<output_bytes do output[index] = encoded[index]
	return i64(output_bytes)
}
