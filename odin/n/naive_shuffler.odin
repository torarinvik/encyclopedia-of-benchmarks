package naive_shuffler

import "core:c"

MAX_ITEMS :: 256
RNG_MODULUS :: i64(2147483647)
RNG_PERIOD :: i64(2147483646)

@(export)
naive_shuffler :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_ITEMS + 2) do return -1
	if input[0] < 0 || input[0] >= RNG_PERIOD || input[1] < 0 || input[1] > MAX_ITEMS do return -1
	count := int(input[1])
	if length != c.size_t(count + 2) do return -1

	items: [MAX_ITEMS]u8
	for index in 0..<count {
		if input[index + 2] < 0 || input[index + 2] > 255 do return -1
		items[index] = u8(input[index + 2])
	}
	if output_capacity < c.size_t(count) || (count > 0 && output == nil) do return -2

	state := input[0] + 1
	for index in 0..<count {
		bound := i64(count)
		limit := RNG_PERIOD - RNG_PERIOD % bound
		for {
			state = (state * 48271) % RNG_MODULUS
			sample := state - 1
			if sample < limit {
				other := int(sample % bound)
				temporary := items[index]
				items[index] = items[other]
				items[other] = temporary
				break
			}
		}
	}
	for index in 0..<count { output[index] = items[index] }
	return i64(count)
}
