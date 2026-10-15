package cross_correlation

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
cross_correlation :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 66 do return -1
	raw_x_count := values[0]
	raw_y_count := values[1]
	if raw_x_count < 1 || raw_x_count > 32 || raw_y_count < 1 || raw_y_count > 32 do return -1
	x_count := int(raw_x_count)
	y_count := int(raw_y_count)
	if length != c.size_t(x_count + y_count + 2) do return -1
	for index := 0; index < x_count + y_count; index += 1 {
		if values[index + 2] < -1_000_000 || values[index + 2] > 1_000_000 do return -1
	}
	result_count := x_count + y_count - 1
	byte_count := 8 * result_count
	if output == nil || output_capacity < c.size_t(byte_count) do return -2

	y_start := y_count
	for index := 0; index < result_count; index += 1 {
		if index < y_count do y_start -= 1
		k_min := if index >= y_count - 1 { index - (y_count - 1) } else { 0 }
		k_max := if index < x_count { index } else { x_count - 1 }
		sum := i64(0)
		for k := k_min; k <= k_max; k += 1 {
			y_index := y_start + (k - k_min)
			sum += values[k + 2] * values[x_count + y_index + 2]
		}
		store_i64_le(output, index * 8, sum)
	}
	return i64(byte_count)
}
