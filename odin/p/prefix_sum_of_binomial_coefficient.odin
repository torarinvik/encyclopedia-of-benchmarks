package prefix_sum_of_binomial_coefficient

import "core:c"

MODULUS :: i64(998244353)

prefix_sum_of_binomial_coefficient :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 34 do return -1
	count_value := input[0]
	if count_value < 1 || count_value > 16 do return -1
	count := int(count_value)
	if length != c.size_t(1 + 2 * count) do return -1
	var ns: [16]i64
	var ks: [16]i64
	for query := 0; query < count; query += 1 {
		ns[query] = input[1 + 2 * query]
		ks[query] = input[2 + 2 * query]
		if ns[query] < 0 || ns[query] > 128 || ks[query] < 0 || ks[query] > ns[query] do return -1
	}
	output_length := c.size_t(4 * count)
	if output == nil || capacity < output_length do return -2

	var inverse: [129]i64
	inverse[1] = 1
	for value := 2; value <= 128; value += 1 {
		inverse[value] = MODULUS - (MODULUS / i64(value)) * inverse[int(MODULUS % i64(value))] % MODULUS
	}
	for query := 0; query < count; query += 1 {
		coefficient, prefix := i64(1), i64(1)
		for index := i64(0); index < ks[query]; index += 1 {
			coefficient = coefficient * (ns[query] - index) % MODULUS
			coefficient = coefficient * inverse[int(index + 1)] % MODULUS
			prefix = (prefix + coefficient) % MODULUS
		}
		offset := 4 * query
		output[offset] = u8(prefix % 256)
		output[offset + 1] = u8((prefix / 256) % 256)
		output[offset + 2] = u8((prefix / 65_536) % 256)
		output[offset + 3] = u8(prefix / 16_777_216)
	}
	return i64(output_length)
}
