package convolution

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
convolution :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 130 do return -1
	raw_a := values[0]
	raw_b := values[1]
	if raw_a < 1 || raw_a > 64 || raw_b < 1 || raw_b > 64 do return -1
	a_count := int(raw_a)
	b_count := int(raw_b)
	if length != c.size_t(a_count + b_count + 2) do return -1
	for j := 0; j < a_count + b_count; j += 1 {
		if values[j+2] < -1_000_000 || values[j+2] > 1_000_000 do return -1
	}
	result_count := a_count + b_count - 1
	byte_count := result_count * 8
	if output == nil || capacity < c.size_t(byte_count) do return -2
	for i := 0; i < result_count; i += 1 {
		k_start := if i >= b_count - 1 { i - (b_count - 1) } else { 0 }
		k_end := if i < a_count { i } else { a_count - 1 }
		sum := i64(0)
		for k := k_start; k <= k_end; k += 1 { sum += values[k+2] * values[a_count+(i-k)+2] }
		store_i64_le(output, i*8, sum)
	}
	return i64(byte_count)
}
