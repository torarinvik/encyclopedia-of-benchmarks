package huffman_weighted_cost

import "core:c"

MAX_SYMBOLS :: 26
MAX_TOTAL_FREQUENCY :: i64(2_147_483_647)

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
huffman_weighted_cost :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 53 do return -1
	raw_count := values[0]
	if raw_count < 2 || raw_count > MAX_SYMBOLS || length != c.size_t(1 + 2 * raw_count) do return -1
	count := int(raw_count)

	var seen: [MAX_SYMBOLS]bool
	var active: [MAX_SYMBOLS]bool
	var weights: [MAX_SYMBOLS]i64
	total := i64(0)
	for index := 0; index < count; index += 1 {
		symbol := values[1 + 2 * index]
		frequency := values[2 + 2 * index]
		if symbol < 97 || symbol > 122 || frequency < 1 || frequency > MAX_TOTAL_FREQUENCY do return -1
		letter := int(symbol - 97)
		if seen[letter] || total > MAX_TOTAL_FREQUENCY-frequency do return -1
		seen[letter] = true
		active[index] = true
		weights[index] = frequency
		total += frequency
	}

	remaining := count
	cost := i64(0)
	for remaining > 1 {
		first := -1
		second := -1
		for index := 0; index < count; index += 1 {
			if !active[index] do continue
			if first < 0 || weights[index] < weights[first] {
				second = first
				first = index
			} else if second < 0 || weights[index] < weights[second] {
				second = index
			}
		}
		weights[first] += weights[second]
		active[second] = false
		cost += weights[first]
		remaining -= 1
	}

	if output == nil || output_capacity < 8 do return -2
	store_i64_le(output, cost)
	return cost
}
