// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
module sqrt_tree

const max_items = 256
const max_queries = 256
const max_levels = 16
const max_nodes = 512
const max_between = 512
const max_input_values = 770
const value_limit = i64(1_000_000_000)

struct SqrtTreeState {
mut:
	values [max_items]i64
	prefix [max_levels * max_items]i64
	suffix [max_levels * max_items]i64
	between [max_levels * max_between]i64
	used_values [max_levels]int
	used_between [max_levels]int
	node_left [max_nodes]int
	node_right [max_nodes]int
	node_depth [max_nodes]int
	value_offset [max_nodes]int
	between_offset [max_nodes]int
	block_size [max_nodes]int
	block_count [max_nodes]int
	child_start [max_nodes]int
	children [max_nodes]int
	node_count int
	child_count int
}

fn create_node(mut state &SqrtTreeState, left int, right int, depth int) int {
	node := state.node_count
	state.node_count++
	state.node_left[node] = left
	state.node_right[node] = right
	state.node_depth[node] = depth
	return node
}

fn build_node(mut state &SqrtTreeState, node int) {
	left := state.node_left[node]
	right := state.node_right[node]
	node_length := right - left
	depth := state.node_depth[node]
	if node_length <= 2 { return }
	mut block_size := 1
	for block_size * block_size < node_length { block_size++ }
	block_count := (node_length + block_size - 1) / block_size
	value_offset := state.used_values[depth]
	between_offset := state.used_between[depth]
	state.value_offset[node] = value_offset
	state.between_offset[node] = between_offset
	state.block_size[node] = block_size
	state.block_count[node] = block_count
	state.used_values[depth] += node_length
	state.used_between[depth] += block_count * block_count

	mut block_min := [max_items]i64{}
	for block in 0 .. block_count {
		start := left + block * block_size
		finish := min(start + block_size, right)
		first := value_offset + start - left
		state.prefix[depth * max_items + first] = state.values[start]
		for index := start + 1; index < finish; index++ {
			slot := value_offset + index - left
			state.prefix[depth * max_items + slot] = min(state.prefix[depth * max_items + slot - 1], state.values[index])
		}
		last := value_offset + finish - 1 - left
		state.suffix[depth * max_items + last] = state.values[finish - 1]
		for index := finish - 1; index > start; index-- {
			slot := value_offset + index - 1 - left
			state.suffix[depth * max_items + slot] = min(state.values[index - 1], state.suffix[depth * max_items + slot + 1])
		}
		block_min[block] = state.prefix[depth * max_items + last]
	}
	for first in 0 .. block_count {
		mut aggregate := block_min[first]
		for last := first; last < block_count; last++ {
			if last != first { aggregate = min(aggregate, block_min[last]) }
			state.between[depth * max_between + between_offset + first * block_count + last] = aggregate
		}
	}

	child_start := state.child_count
	state.child_start[node] = child_start
	for block in 0 .. block_count {
		start := left + block * block_size
		finish := min(start + block_size, right)
		child := create_node(mut state, start, finish, depth + 1)
		state.children[state.child_count] = child
		state.child_count++
	}
	for block in 0 .. block_count { build_node(mut state, state.children[child_start + block]) }
}

fn query_node(state &SqrtTreeState, node int, left int, right int) i64 {
	node_left := state.node_left[node]
	node_right := state.node_right[node]
	if node_right - node_left <= 2 {
		mut answer := state.values[left]
		for index := left + 1; index <= right; index++ { answer = min(answer, state.values[index]) }
		return answer
	}
	block_size := state.block_size[node]
	left_block := (left - node_left) / block_size
	right_block := (right - node_left) / block_size
	if left_block == right_block {
		return query_node(state, state.children[state.child_start[node] + left_block], left, right)
	}
	depth := state.node_depth[node]
	offset := state.value_offset[node]
	mut answer := state.suffix[depth * max_items + offset + left - node_left]
	if left_block + 1 < right_block {
		count := state.block_count[node]
		middle := state.between_offset[node] + (left_block + 1) * count + right_block - 1
		answer = min(answer, state.between[depth * max_between + middle])
	}
	return min(answer, state.prefix[depth * max_items + offset + right - node_left])
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'sqrt_tree']
pub fn sqrt_tree(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { isnil(input) } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		item_count_value := input[0]
		query_count_value := input[1]
		if item_count_value < 1 || item_count_value > max_items || query_count_value < 0 || query_count_value > max_queries { return -1 }
		item_count := int(item_count_value)
		query_count := int(query_count_value)
		if length != usize(2 + item_count + 2 * query_count) { return -1 }
		for index in 0 .. item_count {
			if input[2 + index] < -value_limit || input[2 + index] > value_limit { return -1 }
		}
		query_offset := 2 + item_count
		for query in 0 .. query_count {
			left := input[query_offset + 2 * query]
			right := input[query_offset + 2 * query + 1]
			if left < 0 || right < left || right >= item_count_value { return -1 }
		}
		required := 8 * query_count
		if output_capacity < usize(required) || (required > 0 && isnil(output)) { return -2 }

		mut state := SqrtTreeState{}
		for index in 0 .. item_count { state.values[index] = input[index + 2] }
		root := create_node(mut state, 0, item_count, 0)
		build_node(mut state, root)
		for query in 0 .. query_count {
			left := int(input[query_offset + 2 * query])
			right := int(input[query_offset + 2 * query + 1])
			store_i64_le(mut output, 8 * query, query_node(state, root, left, right))
		}
		return i64(required)
	}
}
