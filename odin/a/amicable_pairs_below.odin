package amicable_pairs_below

import "core:c"

MAX_LIMIT :: 8_000

write_u32_le :: proc "contextless" (output: [^]u8, position: ^c.size_t, value: i64) {
	encoded := u32(value)
	for byte := u32(0); byte < 4; byte += 1 {
		output[position^] = u8((encoded >> (byte * 8)) & 0xff)
		position^ += 1
	}
}

@(export)
amicable_pairs_below :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	if values[0] < 1 || values[0] > MAX_LIMIT do return -1
	limit := c.size_t(values[0])
	divisor_sums: [MAX_LIMIT]i64
	for index := c.size_t(0); index < MAX_LIMIT; index += 1 do divisor_sums[index] = 0
	for divisor := c.size_t(1); divisor < limit; divisor += 1 {
		for multiple := divisor * 2; multiple < limit; multiple += divisor {
			divisor_sums[multiple] += i64(divisor)
		}
	}

	pair_count := c.size_t(0)
	for smaller := c.size_t(2); smaller < limit; smaller += 1 {
		larger := divisor_sums[smaller]
		if larger > i64(smaller) && larger < i64(limit) && divisor_sums[c.size_t(larger)] == i64(smaller) {
			pair_count += 1
		}
	}
	required := pair_count * 8
	if output_capacity < required || (required > 0 && output == nil) do return -2

	position := c.size_t(0)
	for smaller := c.size_t(2); smaller < limit; smaller += 1 {
		larger := divisor_sums[smaller]
		if larger > i64(smaller) && larger < i64(limit) && divisor_sums[c.size_t(larger)] == i64(smaller) {
			write_u32_le(output, &position, i64(smaller))
			write_u32_le(output, &position, larger)
		}
	}
	return i64(pair_count)
}
