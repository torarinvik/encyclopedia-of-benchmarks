module sqrt_tree_constant_time

const max_n = 64
const max_q = 64
const max_levels = 4
const max_input = 195
const value_limit = i64(1000000000)
const infinity = i64(0x7fffffffffffffff)

struct SqrtTreeState {
mut:
	values [max_n]i64
	prefix [max_levels * max_n]i64
	suffix [max_levels * max_n]i64
	between [max_levels * max_n]i64
	floor_log [max_n + 1]int
	padded int
	layer_count int
	segment_bits [max_levels]int
	block_bits [max_levels]int
	layer_for_diff [max_levels + 3]int
}

fn build(mut state SqrtTreeState, input &i64, n int) {
	mut padded := 1
	for padded < n { padded *= 2 }
	state.padded = padded
	for i in 0 .. n { state.values[i] = input[2 + i] }
	for i := n; i < padded; i++ { state.values[i] = infinity }
	state.floor_log[0] = 0
	state.floor_log[1] = 0
	for i := 2; i <= padded; i++ { state.floor_log[i] = state.floor_log[i / 2] + 1 }
	for i in 0 .. max_levels + 3 { state.layer_for_diff[i] = -1 }
	mut bits := state.floor_log[padded]
	for bits > 1 {
		level := state.layer_count
		state.layer_count++
		block_bits := (bits + 1) / 2
		state.segment_bits[level] = bits
		state.block_bits[level] = block_bits
		for bit := block_bits; bit < bits; bit++ { state.layer_for_diff[bit] = level }
		bits = block_bits
	}

	for level in 0 .. state.layer_count {
		segment_bits := state.segment_bits[level]
		block_bits := state.block_bits[level]
		segment_size := 1 << segment_bits
		block_size := 1 << block_bits
		block_count := segment_size / block_size
		pair_count := block_count * block_count
		for mut base := 0; base < padded; base += segment_size {
			segment_index := base / segment_size
			for block in 0 .. block_count {
				start := base + block * block_size
				end := start + block_size
				state.prefix[level * max_n + start] = state.values[start]
				for pos := start + 1; pos < end; pos++ {
					state.prefix[level * max_n + pos] = min(state.prefix[level * max_n + pos - 1], state.values[pos])
				}
				state.suffix[level * max_n + end - 1] = state.values[end - 1]
				for mut pos := end - 1; pos > start; pos-- {
					state.suffix[level * max_n + pos - 1] = min(state.values[pos - 1], state.suffix[level * max_n + pos])
				}
			}
			for left_block in 0 .. block_count {
				mut aggregate := infinity
				for right_block := left_block; right_block < block_count; right_block++ {
					start := base + right_block * block_size
					aggregate = min(aggregate, state.suffix[level * max_n + start])
					slot := segment_index * pair_count + left_block * block_count + right_block
					state.between[level * max_n + slot] = aggregate
				}
			}
		}
	}
}

fn query(state &SqrtTreeState, left int, right int) i64 {
	if left == right { return state.values[left] }
	bit := state.floor_log[left ^ right]
	if bit == 0 { return min(state.values[left], state.values[right]) }
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
	mut answer := min(state.suffix[level * max_n + left], state.prefix[level * max_n + right])
	if left_block + 1 < right_block {
		pair_count := block_count * block_count
		slot := segment_index * pair_count + (left_block + 1) * block_count + right_block - 1
		answer = min(answer, state.between[level * max_n + slot])
	}
	return answer
}

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'sqrt_tree_constant_time']
pub fn sqrt_tree_constant_time(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
	n, q := int(n_value), int(q_value)
	if length != usize(2 + n + 2 * q) { return -1 }
	for i in 0 .. n { if input[2 + i] < -value_limit || input[2 + i] > value_limit { return -1 } }
	query_offset := 2 + n
	for i in 0 .. q {
		left, right := input[query_offset + 2 * i], input[query_offset + 2 * i + 1]
		if left < 0 || right < left || right >= n_value { return -1 }
	}
	required := usize(8 * q)
	if capacity < required || (required > 0 && unsafe { output == nil }) { return -2 }
	mut state := SqrtTreeState{}
	build(mut state, input, n)
	for i in 0 .. q {
		left, right := int(input[query_offset + 2 * i]), int(input[query_offset + 2 * i + 1])
		store_i64_le(output, 8 * i, query(state, left, right))
	}
	return i64(required)
}
