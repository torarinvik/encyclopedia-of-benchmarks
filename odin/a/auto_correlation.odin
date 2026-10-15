package auto_correlation

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
auto_correlation :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 65 do return -1
	raw_count := values[0]
	if raw_count < 1 || raw_count > 64 do return -1
	count := int(raw_count)
	if length != c.size_t(count + 1) do return -1
	for index := 0; index < count; index += 1 {
		if values[index + 1] < -1_000_000 || values[index + 1] > 1_000_000 do return -1
	}
	result_count := 2 * count - 1
	byte_count := 8 * result_count
	if output == nil || output_capacity < c.size_t(byte_count) do return -2

	y_start := count
	for index := 0; index < result_count; index += 1 {
		if index < count do y_start -= 1
		k_min := if index >= count - 1 { index - (count - 1) } else { 0 }
		k_max := if index < count { index } else { count - 1 }
		offset := 0
		sum := i64(0)
		for k := k_min; k <= k_max; k += 1 {
			sum += values[k + 1] * values[y_start + offset + 1]
			offset += 1
		}
		store_i64_le(output, index * 8, sum)
	}
	return i64(byte_count)
}
