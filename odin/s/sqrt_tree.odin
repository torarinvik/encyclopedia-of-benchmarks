// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
package sqrt_tree

import "core:c"

MAX_ITEMS :: 256
MAX_QUERIES :: 256
MAX_LEVELS :: 16
MAX_NODES :: 512
MAX_BETWEEN :: 512
MAX_INPUT_VALUES :: c.size_t(770)
VALUE_LIMIT :: i64(1_000_000_000)

State :: struct {
	values: [MAX_ITEMS]i64,
	prefix: [MAX_LEVELS * MAX_ITEMS]i64,
	suffix: [MAX_LEVELS * MAX_ITEMS]i64,
	between: [MAX_LEVELS * MAX_BETWEEN]i64,
	used_values: [MAX_LEVELS]int,
	used_between: [MAX_LEVELS]int,
	node_left: [MAX_NODES]int,
	node_right: [MAX_NODES]int,
	node_depth: [MAX_NODES]int,
	value_offset: [MAX_NODES]int,
	between_offset: [MAX_NODES]int,
	block_size: [MAX_NODES]int,
	block_count: [MAX_NODES]int,
	child_start: [MAX_NODES]int,
	children: [MAX_NODES]int,
	node_count: int,
	child_count: int,
}

create_node :: proc(state: ^State, left, right, depth: int) -> int {
	node := state.node_count
	state.node_count += 1
	state.node_left[node] = left
	state.node_right[node] = right
	state.node_depth[node] = depth
	return node
}

build_node :: proc(state: ^State, node: int) {
	left := state.node_left[node]
	right := state.node_right[node]
	node_length := right - left
	depth := state.node_depth[node]
	if node_length <= 2 do return
	block_size := 1
	for block_size * block_size < node_length { block_size += 1 }
	block_count := (node_length + block_size - 1) / block_size
	value_offset := state.used_values[depth]
	between_offset := state.used_between[depth]
	state.value_offset[node] = value_offset
	state.between_offset[node] = between_offset
	state.block_size[node] = block_size
	state.block_count[node] = block_count
	state.used_values[depth] += node_length
	state.used_between[depth] += block_count * block_count

	var block_min: [MAX_ITEMS]i64
	for block in 0 ..< block_count {
		start := left + block * block_size
		finish := min(start + block_size, right)
		first := value_offset + start - left
		state.prefix[depth * MAX_ITEMS + first] = state.values[start]
		for index in start+1 ..< finish {
			slot := value_offset + index - left
			state.prefix[depth * MAX_ITEMS + slot] = min(state.prefix[depth * MAX_ITEMS + slot - 1], state.values[index])
		}
		last := value_offset + finish - 1 - left
		state.suffix[depth * MAX_ITEMS + last] = state.values[finish-1]
		for index := finish - 1; index > start; index -= 1 {
			slot := value_offset + index - 1 - left
			state.suffix[depth * MAX_ITEMS + slot] = min(state.values[index-1], state.suffix[depth * MAX_ITEMS + slot + 1])
		}
		block_min[block] = state.prefix[depth * MAX_ITEMS + last]
	}
	for first in 0 ..< block_count {
		aggregate := block_min[first]
		for last in first ..< block_count {
			if last != first { aggregate = min(aggregate, block_min[last]) }
			state.between[depth * MAX_BETWEEN + between_offset + first * block_count + last] = aggregate
		}
	}

	child_start := state.child_count
	state.child_start[node] = child_start
	for block in 0 ..< block_count {
		start := left + block * block_size
		finish := min(start + block_size, right)
		child := create_node(state, start, finish, depth + 1)
		state.children[state.child_count] = child
		state.child_count += 1
	}
	for block in 0 ..< block_count { build_node(state, state.children[child_start + block]) }
}

query_node :: proc(state: ^State, node, left, right: int) -> i64 {
	node_left := state.node_left[node]
	node_right := state.node_right[node]
	if node_right-node_left <= 2 {
		answer := state.values[left]
		for index := left + 1; index <= right; index += 1 { answer = min(answer, state.values[index]) }
		return answer
	}
	block_size := state.block_size[node]
	left_block := (left-node_left)/block_size
	right_block := (right-node_left)/block_size
	if left_block == right_block {
		return query_node(state, state.children[state.child_start[node]+left_block], left, right)
	}
	depth := state.node_depth[node]
	offset := state.value_offset[node]
	answer := state.suffix[depth*MAX_ITEMS+offset+left-node_left]
	if left_block+1 < right_block {
		count := state.block_count[node]
		middle := state.between_offset[node]+(left_block+1)*count+right_block-1
		answer = min(answer, state.between[depth*MAX_BETWEEN+middle])
	}
	return min(answer, state.prefix[depth*MAX_ITEMS+offset+right-node_left])
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := cast(u64)value
	for byte in 0 ..< 8 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="sqrt_tree")
sqrt_tree :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	item_count_value := input[0]
	query_count_value := input[1]
	if item_count_value < 1 || item_count_value > MAX_ITEMS || query_count_value < 0 || query_count_value > MAX_QUERIES do return -1
	item_count := int(item_count_value)
	query_count := int(query_count_value)
	if length != c.size_t(2+item_count+2*query_count) do return -1
	for index in 0 ..< item_count {
		if input[2+index] < -VALUE_LIMIT || input[2+index] > VALUE_LIMIT do return -1
	}
	query_offset := 2+item_count
	for query in 0 ..< query_count {
		left, right := input[query_offset+2*query], input[query_offset+2*query+1]
		if left < 0 || right < left || right >= item_count_value do return -1
	}
	required := c.size_t(8*query_count)
	if output_capacity < required || (required != 0 && output == nil) do return -2

	var state: State
	for index in 0 ..< item_count { state.values[index] = input[index+2] }
	root := create_node(&state, 0, item_count, 0)
	build_node(&state, root)
	for query in 0 ..< query_count {
		left, right := int(input[query_offset+2*query]), int(input[query_offset+2*query+1])
		store_i64_le(output, 8*query, query_node(&state, root, left, right))
	}
	return i64(required)
}
