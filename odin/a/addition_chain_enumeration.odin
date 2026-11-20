package addition_chain_enumeration

import "core:c"

MAX_TARGET :: 31
OUTPUT_BYTES :: 24

Search :: struct {
	target: int,
	limit: int,
	chain: [32]int,
	total_count: i64,
	brauer_count: i64,
}

visit :: proc(state: ^Search, length: int, prefix_is_brauer: bool) {
	last := state.chain[length-1]
	steps := length - 1
	if last == state.target {
		if steps == state.limit {
			state.total_count += 1
			if prefix_is_brauer do state.brauer_count += 1
		}
		return
	}
	remaining := state.limit - steps
	if remaining <= 0 || last * (1 << remaining) < state.target do return

	generated: [32]bool = {}
	for left := 0; left < length; left += 1 {
		for right := left; right < length; right += 1 {
			candidate := state.chain[left] + state.chain[right]
			if candidate <= last || candidate > state.target || generated[candidate] do continue
			generated[candidate] = true
			state.chain[length] = candidate
			uses_last := false
			for index := 0; index < length; index += 1 {
				if last + state.chain[index] == candidate do uses_last = true
			}
			visit(state, length+1, prefix_is_brauer && uses_last)
		}
	}
}

bit_length :: proc(value_input: int) -> int {
	value := value_input
	count := 0
	for value != 0 {
		count += 1
		value >>= 1
	}
	return count
}

popcount :: proc(value_input: int) -> int {
	value := value_input
	count := 0
	for value != 0 {
		count += value & 1
		value >>= 1
	}
	return count
}

minimum_counts :: proc(target: int) -> [3]i64 {
	if target == 1 do return [3]i64{0, 1, 0}
	lower := bit_length(target - 1)
	upper := bit_length(target) - 1 + popcount(target) - 1
	for limit := lower; limit <= upper; limit += 1 {
		state := Search{target = target, limit = limit}
		state.chain[0] = 1
		visit(&state, 1, true)
		if state.total_count != 0 {
			return [3]i64{i64(limit), state.brauer_count, state.total_count - state.brauer_count}
		}
	}
	return [3]i64{}
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte * 8)) }
}

@(export)
addition_chain_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	target_value := input[0]
	if target_value < 1 || target_value > MAX_TARGET do return -1
	result := minimum_counts(int(target_value))
	if output == nil || output_capacity < OUTPUT_BYTES do return -2
	for index := 0; index < 3; index += 1 { store_i64_le(output, index*8, result[index]) }
	return OUTPUT_BYTES
}
