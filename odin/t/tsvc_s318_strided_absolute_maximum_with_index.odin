package tsvc_s318_strided_absolute_maximum_with_index

import "core:c"

MAX_N :: 64
MAX_STRIDE :: 4
MAX_PHYSICAL_N :: 1 + (MAX_N - 1) * MAX_STRIDE
MAX_INPUT_LENGTH :: 2 + MAX_PHYSICAL_N
MAX_VALUE :: i64(1_000_000)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s318_strided_absolute_maximum_with_index :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	stride_raw := input[1]
	if n_raw < 1 || n_raw > MAX_N || stride_raw < 1 || stride_raw > MAX_STRIDE do return -1
	n := int(n_raw)
	stride := int(stride_raw)
	physical_n := 1 + (n - 1) * stride
	if int(length) != 2 + physical_n do return -1
	for i := 0; i < physical_n; i += 1 {
		if input[i + 2] < -MAX_VALUE || input[i + 2] > MAX_VALUE do return -1
	}
	if output == nil || output_capacity < 16 do return -2

	first := input[2]
	maximum := first
	if maximum < 0 do maximum = -maximum
	maximum_index := 0
	for i := 1; i < n; i += 1 {
		value := input[2 + i * stride]
		magnitude := value
		if magnitude < 0 do magnitude = -magnitude
		if magnitude > maximum {
			maximum = magnitude
			maximum_index = i
		}
	}
	store_i64_le(output, 0, maximum)
	store_i64_le(output, 8, i64(maximum_index))
	return 2
}
