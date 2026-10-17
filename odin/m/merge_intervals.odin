package merge_intervals

import "core:c"

MAX_INTERVALS :: 256
MAX_INPUT_LENGTH :: 1 + 2 * MAX_INTERVALS

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
merge_intervals :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > MAX_INTERVALS do return -1
	count := int(raw_count)
	if length != c.size_t(1 + 2 * count) do return -1

	starts: [MAX_INTERVALS]i64
	ends: [MAX_INTERVALS]i64
	for index := 0; index < count; index += 1 {
		start := values[1 + 2 * index]
		ending := values[2 + 2 * index]
		if start < -2_147_483_648 || start > 2_147_483_647 ||
			ending < -2_147_483_648 || ending > 2_147_483_647 || start > ending do return -1
		starts[index] = start
		ends[index] = ending
	}

	for index := 1; index < count; index += 1 {
		start := starts[index]
		ending := ends[index]
		position := index
		for position > 0 && starts[position - 1] > start {
			starts[position] = starts[position - 1]
			ends[position] = ends[position - 1]
			position -= 1
		}
		starts[position] = start
		ends[position] = ending
	}

	merged := 0
	for index := 0; index < count; index += 1 {
		if merged > 0 && starts[index] <= ends[merged - 1] {
			if ends[index] > ends[merged - 1] do ends[merged - 1] = ends[index]
		} else {
			starts[merged] = starts[index]
			ends[merged] = ends[index]
			merged += 1
		}
	}

	byte_count := 8 * merged
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for index := 0; index < merged; index += 1 {
		store_i32_le(output, index * 8, starts[index])
		store_i32_le(output, index * 8 + 4, ends[index])
	}
	return i64(byte_count)
}
