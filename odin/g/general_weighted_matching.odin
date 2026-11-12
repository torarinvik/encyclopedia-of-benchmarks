package general_weighted_matching

import "core:c"

MAX_N :: 16
MAX_STATES :: 1 << MAX_N
MAX_OUTPUT_WORDS :: 2 + MAX_N
MAX_INPUT_VALUES :: 2 + 3 * (MAX_N * (MAX_N - 1) / 2) + 1
MAX_WEIGHT :: i64(1_000_000)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (byte * 8))
	}
}

@(export)
general_weighted_matching :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	nv, mv := input[0], input[1]
	if nv < 1 || nv > MAX_N || mv < 0 || mv > nv * (nv - 1) / 2 do return -1
	n, m := int(nv), int(mv)
	if length != c.size_t(2 + 3 * m) do return -1

	var weights: [MAX_N][MAX_N]i64
	var present: [MAX_N][MAX_N]bool
	cursor := 2
	for _ in 0 .. m {
		uv, vv, edge_weight := input[cursor], input[cursor + 1], input[cursor + 2]
		cursor += 3
		if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv ||
			edge_weight < 1 || edge_weight > MAX_WEIGHT do return -1
		u, v := int(uv), int(vv)
		if present[u][v] do return -1
		present[u][v], present[v][u] = true, true
		weights[u][v], weights[v][u] = edge_weight, edge_weight
	}

	var dp: [MAX_STATES]i64
	state_count := 1 << n
	for mask := 1; mask < state_count; mask += 1 {
		bit := mask & -mask
		vertex := 0
		for (bit >> vertex) != 1 { vertex += 1 }
		remainder := mask ^ bit
		dp[mask] = dp[remainder]
		for partner := vertex + 1; partner < n; partner += 1 {
			partner_bit := 1 << partner
			if (remainder & partner_bit) == 0 || !present[vertex][partner] do continue
			candidate := weights[vertex][partner] + dp[remainder ^ partner_bit]
			if candidate > dp[mask] do dp[mask] = candidate
		}
	}

	var words: [MAX_OUTPUT_WORDS]i64
	pair_count := 0
	mask := state_count - 1
	for mask != 0 {
		bit := mask & -mask
		vertex := 0
		for (bit >> vertex) != 1 { vertex += 1 }
		remainder := mask ^ bit
		if dp[mask] == dp[remainder] {
			mask = remainder
			continue
		}
		selected := -1
		for partner := vertex + 1; partner < n; partner += 1 {
			partner_bit := 1 << partner
			if (remainder & partner_bit) != 0 && present[vertex][partner] &&
				weights[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask] {
				selected = partner
				break
			}
		}
		if selected < 0 do return -1
		words[2 + 2 * pair_count], words[3 + 2 * pair_count] = i64(vertex), i64(selected)
		pair_count += 1
		mask = remainder ^ (1 << selected)
	}
	words[0], words[1] = i64(pair_count), dp[state_count - 1]
	output_bytes := c.size_t(8 * (2 + 2 * pair_count))
	if output == nil || capacity < output_bytes do return -2
	for word := 0; word < 2 + 2 * pair_count; word += 1 {
		store_i64_le(output, 8 * word, words[word])
	}
	return i64(output_bytes)
}
