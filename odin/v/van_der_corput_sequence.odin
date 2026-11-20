package van_der_corput_sequence

import "core:c"

MAX_INDEX :: 4096
MAX_COUNT :: 128

store_u64_le :: proc(output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((value >> (byte * 8)) & 255)
	}
}

@(export)
van_der_corput_sequence :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	base, first_index, count := input[0], input[1], input[2]
	if base < 2 || base > 16 || first_index < 1 || first_index > MAX_INDEX
		|| count < 0 || count > MAX_COUNT
		|| (count > 0 && first_index + count - 1 > MAX_INDEX) do return -1

	output_bytes := int(count) * 16
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for offset := 0; offset < int(count); offset += 1 {
		index := first_index + i64(offset)
		numerator: u64 = 0
		denominator: u64 = 1
		for index > 0 {
			numerator = numerator * u64(base) + u64(index % base)
			denominator *= u64(base)
			index /= base
		}
		position := offset * 16
		store_u64_le(output, position, numerator)
		store_u64_le(output, position + 8, denominator)
	}
	return i64(output_bytes)
}
