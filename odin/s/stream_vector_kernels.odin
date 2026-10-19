package stream_vector_kernels

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

stream_vector_kernels :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 259 do return -1
	mode, count_value := input[0], input[1]
	if mode < 0 || mode > 3 || count_value < 0 || count_value > 128 do return -1
	count := int(count_value)
	has_alpha := mode == 1 || mode == 3
	array_count := 1
	if mode == 2 || mode == 3 do array_count = 2
	expected_length := 2 + array_count * count
	if has_alpha do expected_length += 1
	if int(length) != expected_length do return -1

	a_start := 2
	alpha: i64 = 0
	if has_alpha {
		alpha = input[2]
		if alpha < -1000 || alpha > 1000 do return -1
		a_start = 3
	}
	b_start := a_start + count
	for index := 0; index < array_count * count; index += 1 {
		value := input[a_start + index]
		if value < -1000 || value > 1000 do return -1
	}

	staged: [128]i64
	for index := 0; index < count; index += 1 {
		a := input[a_start + index]
		value: i64
		if mode == 0 do value = a
		else if mode == 1 do value = alpha * a
		else if mode == 2 do value = a + input[b_start + index]
		else do value = a + alpha * input[b_start + index]
		staged[index] = value
	}

	output_bytes := count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < count; index += 1 {
		write_i64_le(output, index * 8, staged[index])
	}
	return i64(output_bytes)
}
