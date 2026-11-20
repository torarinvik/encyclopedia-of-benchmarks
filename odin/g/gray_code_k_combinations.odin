package gray_code_k_combinations

import "core:c"

@(export)
gray_code_k_combinations :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 || input[0] < 0 || input[0] > 12 ||
		input[1] < 0 || input[1] > input[0] do return -1
	n, k := int(input[0]), int(input[1])
	smaller := k
	if smaller > n-k do smaller = n-k
	count := 1
	for factor := 1; factor <= smaller; factor += 1 {
		count = count * (n-smaller+factor) / factor
	}
	required := c.size_t(2 + 2*count)
	if output == nil || capacity < required do return -2
	output[0] = u8(count & 255)
	output[1] = u8((count >> 8) & 255)

	emitted := 0
	for index := 0; index < (1 << n); index += 1 {
		mask := index ^ (index >> 1)
		remaining, population := mask, 0
		for remaining > 0 {
			remaining &= remaining - 1
			population += 1
		}
		if population == k {
			output[2+2*emitted] = u8(mask & 255)
			output[3+2*emitted] = u8((mask >> 8) & 255)
			emitted += 1
		}
	}
	return i64(count)
}
