package sqrt_tree_constant_time

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_LEVELS :: 4
MAX_INPUT :: 195
VALUE_LIMIT :: i64(1_000_000_000)
INF :: i64(0x7fffffffffffffff)

State :: struct {
	values: [MAX_N]i64,
	prefix: [MAX_LEVELS * MAX_N]i64,
	suffix: [MAX_LEVELS * MAX_N]i64,
	between: [MAX_LEVELS * MAX_N]i64,
	floor_log: [MAX_N + 1]int,
	padded, layer_count: int,
	segment_bits, block_bits: [MAX_LEVELS]int,
	layer_for_diff: [MAX_LEVELS + 3]int,
}

build :: proc(state: ^State, input: [^]i64, n: int) {
	padded := 1
	for padded < n { padded *= 2 }
	state.padded = padded
	for i := 0; i < n; i += 1 { state.values[i] = input[2 + i] }
	for i := n; i < padded; i += 1 { state.values[i] = INF }
	state.floor_log[0] = 0
	state.floor_log[1] = 0
	for i := 2; i <= padded; i += 1 { state.floor_log[i] = state.floor_log[i / 2] + 1 }
	for i := 0; i < MAX_LEVELS + 3; i += 1 { state.layer_for_diff[i] = -1 }
	bits := state.floor_log[padded]
	for bits > 1 {
		level := state.layer_count
		state.layer_count += 1
		block_bits := (bits + 1) / 2
		state.segment_bits[level] = bits
		state.block_bits[level] = block_bits
		for bit := block_bits; bit < bits; bit += 1 { state.layer_for_diff[bit] = level }
		bits = block_bits
	}

	for level := 0; level < state.layer_count; level += 1 {
		segment_bits := state.segment_bits[level]
		block_bits := state.block_bits[level]
		segment_size := 1 << segment_bits
		block_size := 1 << block_bits
		block_count := segment_size / block_size
		pair_count := block_count * block_count
		for base := 0; base < padded; base += segment_size {
			segment_index := base / segment_size
			for block := 0; block < block_count; block += 1 {
				start := base + block * block_size
				end := start + block_size
				state.prefix[level * MAX_N + start] = state.values[start]
				for pos := start + 1; pos < end; pos += 1 {
					state.prefix[level * MAX_N + pos] = min(state.prefix[level * MAX_N + pos - 1], state.values[pos])
				}
				state.suffix[level * MAX_N + end - 1] = state.values[end - 1]
				for pos := end - 1; pos > start; pos -= 1 {
					state.suffix[level * MAX_N + pos - 1] = min(state.values[pos - 1], state.suffix[level * MAX_N + pos])
				}
			}
			for left_block := 0; left_block < block_count; left_block += 1 {
				aggregate := INF
				for right_block := left_block; right_block < block_count; right_block += 1 {
					start := base + right_block * block_size
					aggregate = min(aggregate, state.suffix[level * MAX_N + start])
					slot := segment_index * pair_count + left_block * block_count + right_block
					state.between[level * MAX_N + slot] = aggregate
				}
			}
		}
	}
}

query :: proc(state: ^State, left, right: int) -> i64 {
	if left == right do return state.values[left]
	bit := state.floor_log[left ^ right]
	if bit == 0 do return min(state.values[left], state.values[right])
	level := state.layer_for_diff[bit]
	segment_bits := state.segment_bits[level]
	block_bits := state.block_bits[level]
	segment_size := 1 << segment_bits
	block_size := 1 << block_bits
	base := (left / segment_size) * segment_size
	segment_index := base / segment_size
	block_count := segment_size / block_size
	left_block := (left - base) / block_size
	right_block := (right - base) / block_size
	answer := min(state.suffix[level * MAX_N + left], state.prefix[level * MAX_N + right])
	if left_block + 1 < right_block {
		pair_count := block_count * block_count
		slot := segment_index * pair_count + (left_block + 1) * block_count + right_block - 1
		answer = min(answer, state.between[level * MAX_N + slot])
	}
	return answer
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
sqrt_tree_constant_time :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if int(length) != 2 + n + 2 * q do return -1
	for i := 0; i < n; i += 1 { if input[2 + i] < -VALUE_LIMIT || input[2 + i] > VALUE_LIMIT do return -1 }
	query_offset := 2 + n
	for i := 0; i < q; i += 1 {
		left, right := input[query_offset + 2 * i], input[query_offset + 2 * i + 1]
		if left < 0 || right < left || right >= n_value do return -1
	}
	required := c.size_t(8 * q)
	if capacity < required || (required != 0 && output == nil) do return -2
	state: State
	build(&state, input, n)
	for i := 0; i < q; i += 1 {
		left, right := int(input[query_offset + 2 * i]), int(input[query_offset + 2 * i + 1])
		put_i64_le(output, 8 * i, query(&state, left, right))
	}
	return i64(required)
}
