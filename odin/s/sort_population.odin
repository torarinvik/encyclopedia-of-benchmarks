package sort_population

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

sort_population :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 129 do return -1
	if input[0] < 1 || input[0] > 64 do return -1
	count := c.size_t(input[0])
	if length != 1 + 2 * count do return -1
	costs: [64]i64
	identifiers: [64]i64
	seen: [64]bool
	for index := 0; index < 64; index += 1 { seen[index] = false }
	for index := c.size_t(0); index < count; index += 1 {
		cost := input[1 + 2 * index]
		identifier := input[2 + 2 * index]
		if cost < -1000000 || cost > 1000000 || identifier < 0 || identifier >= i64(count) do return -1
		id := int(identifier)
		if seen[id] do return -1
		seen[id] = true
		costs[index] = cost
		identifiers[index] = identifier
	}
	for index := c.size_t(1); index < count; index += 1 {
		key_cost := costs[index]
		key_identifier := identifiers[index]
		position := index
		for position > 0 && costs[position - 1] > key_cost {
			costs[position] = costs[position - 1]
			identifiers[position] = identifiers[position - 1]
			position -= 1
		}
		costs[position] = key_cost
		identifiers[position] = key_identifier
	}
	for index := c.size_t(1); index < count; index += 1 {
		if costs[index - 1] == costs[index] do return -1
	}
	output_length := count * 16
	if output == nil || capacity < output_length do return -2
	for index := c.size_t(0); index < count; index += 1 {
		write_i64_le(output, int(index * 16), costs[index])
		write_i64_le(output, int(index * 16 + 8), identifiers[index])
	}
	return i64(output_length)
}
