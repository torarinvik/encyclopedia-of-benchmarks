package quine_mccluskey_minimization

import "core:c"

MAX_VARIABLES :: 3
MAX_CUBES :: 27
MAX_STATES :: 256
MAX_INPUT_LENGTH :: 9
INF_COST :: 99

cube_valid :: proc(care, value: u32, input: [^]i64, size: int) -> bool {
	cover: u32 = 0
	for minterm := 0; minterm < size; minterm += 1 {
		if (u32(minterm) & care) == value {
			status := input[1 + minterm]
			if status == 0 do return false
			if status == 1 { cover |= 1 << u32(minterm) }
		}
	}
	return cover != 0
}

lex_better :: proc(candidate, incumbent: u32, count: int) -> bool {
	for index := 0; index < count; index += 1 {
		bit := 1 << u32(index)
		left := (candidate & bit) != 0
		right := (incumbent & bit) != 0
		if left != right do return left
	}
	return false
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="quine_mccluskey_minimization")
quine_mccluskey_minimization :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_VARIABLES do return -1
	n := int(input[0])
	size := 1 << n
	if length != c.size_t(1 + size) do return -1
	for minterm := 0; minterm < size; minterm += 1 {
		if input[1 + minterm] < 0 || input[1 + minterm] > 2 do return -1
	}

	cares: [MAX_CUBES]u32
	values: [MAX_CUBES]u32
	covers: [MAX_CUBES]u32
	literal_counts: [MAX_CUBES]int
	prime_count := 0
	full := u32(size - 1)
	for care := u32(0); care <= full; care += 1 {
		for value := u32(0); value <= full; value += 1 {
			if (value & ~care) != 0 || !cube_valid(care, value, &input[0], size) do continue
			prime := true
			for variable := 0; variable < n; variable += 1 {
				bit := 1 << u32(variable)
				if (care & bit) != 0 && cube_valid(care ^ bit, value & ~bit, &input[0], size) {
					prime = false
					break
				}
			}
			if !prime do continue
			cover: u32 = 0
			literal_count := 0
			for minterm := 0; minterm < size; minterm += 1 {
				if (u32(minterm) & care) == value && input[1 + minterm] == 1 {
					cover |= 1 << u32(minterm)
				}
			}
			for variable := 0; variable < n; variable += 1 {
				if (care & (1 << u32(variable))) != 0 { literal_count += 1 }
			}
			cares[prime_count] = care
			values[prime_count] = value
			covers[prime_count] = cover
			literal_counts[prime_count] = literal_count
			prime_count += 1
		}
	}
	on_mask: u32 = 0
	for minterm := 0; minterm < size; minterm += 1 {
		if input[1 + minterm] == 1 { on_mask |= 1 << u32(minterm) }
	}
	state_count := 1 << size
	term_cost: [MAX_STATES]int
	literal_cost: [MAX_STATES]int
	selected: [MAX_STATES]u32
	for state := 0; state < state_count; state += 1 {
		term_cost[state] = INF_COST
		literal_cost[state] = INF_COST
		selected[state] = 0
	}
	term_cost[0] = 0
	literal_cost[0] = 0
	for index := 0; index < prime_count; index += 1 {
		prime_bit := 1 << u32(index)
		for state := state_count - 1; state >= 0; state -= 1 {
			if term_cost[state] == INF_COST do continue
			destination := state | int(covers[index])
			if destination == state do continue
			new_terms := term_cost[state] + 1
			new_literals := literal_cost[state] + literal_counts[index]
			new_selected := selected[state] | prime_bit
			better := new_terms < term_cost[destination]
			if new_terms == term_cost[destination] {
				better = new_literals < literal_cost[destination]
				if new_literals == literal_cost[destination] {
					better = lex_better(new_selected, selected[destination], prime_count)
				}
			}
			if better {
				term_cost[destination] = new_terms
				literal_cost[destination] = new_literals
				selected[destination] = new_selected
			}
		}
	}
	chosen := selected[int(on_mask)]
	term_count := 0
	for index := 0; index < prime_count; index += 1 {
		if (chosen & (1 << u32(index))) != 0 { term_count += 1 }
	}
	output_bytes := c.size_t(8 * (1 + 2 * term_count))
	if output == nil || capacity < output_bytes do return -2
	store_i64_le(output, 0, i64(term_count))
	cursor := 1
	for index := 0; index < prime_count; index += 1 {
		if (chosen & (1 << u32(index))) != 0 {
			store_i64_le(output, cursor * 8, i64(cares[index]))
			cursor += 1
			store_i64_le(output, cursor * 8, i64(values[index]))
			cursor += 1
		}
	}
	return i64(output_bytes)
}
