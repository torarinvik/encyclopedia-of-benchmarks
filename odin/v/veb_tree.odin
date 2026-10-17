package veb_tree

import "core:c"

MAX_COUNT :: 256
MAX_INPUT_VALUES :: 771
MAX_OUTPUT_BYTES :: 1024
MAX_TREE_NODES :: 358
MAX_CLUSTERS :: 16

Veb_Node :: struct {
	universe: int,
	low_bits: int,
	cluster_count: int,
	minimum: i32,
	maximum: i32,
	summary: int,
	clusters: [MAX_CLUSTERS]int,
}

initialize :: proc "contextless" (nodes: ^[MAX_TREE_NODES]Veb_Node, next: ^int, universe: int) -> int {
	id := next^
	next^ += 1
	nodes[id].universe = universe
	nodes[id].low_bits = 0
	nodes[id].cluster_count = 0
	nodes[id].minimum = -1
	nodes[id].maximum = 0
	nodes[id].summary = -1
	if universe > 2 {
		exponent := 0
		remaining := universe
		for remaining > 1 {
			remaining /= 2
			exponent += 1
		}
		low_bits := exponent / 2
		low_size := 1 << low_bits
		cluster_count := universe / low_size
		nodes[id].low_bits = low_bits
		nodes[id].cluster_count = cluster_count
		nodes[id].summary = initialize(nodes, next, cluster_count)
		for i := 0; i < cluster_count; i += 1 {
			nodes[id].clusters[i] = initialize(nodes, next, low_size)
		}
	}
	return id
}

contains :: proc "contextless" (nodes: ^[MAX_TREE_NODES]Veb_Node, id: int, value: int) -> bool {
	if nodes[id].minimum < 0 do return false
	if nodes[id].minimum == i32(value) || nodes[id].maximum == i32(value) do return true
	if nodes[id].universe == 2 do return false
	low_size := 1 << nodes[id].low_bits
	high := value >> nodes[id].low_bits
	low := value & (low_size - 1)
	return contains(nodes, nodes[id].clusters[high], low)
}

insert :: proc "contextless" (nodes: ^[MAX_TREE_NODES]Veb_Node, id: int, initial_value: int) {
	if contains(nodes, id, initial_value) do return
	if nodes[id].minimum < 0 {
		nodes[id].minimum = i32(initial_value)
		nodes[id].maximum = i32(initial_value)
		return
	}
	value := initial_value
	if value < int(nodes[id].minimum) {
		old_minimum := int(nodes[id].minimum)
		nodes[id].minimum = i32(value)
		value = old_minimum
	}
	if nodes[id].universe > 2 {
		low_size := 1 << nodes[id].low_bits
		high := value >> nodes[id].low_bits
		low := value & (low_size - 1)
		cluster := nodes[id].clusters[high]
		if nodes[cluster].minimum < 0 {
			insert(nodes, nodes[id].summary, high)
			nodes[cluster].minimum = i32(low)
			nodes[cluster].maximum = i32(low)
		} else {
			insert(nodes, cluster, low)
		}
	}
	if value > int(nodes[id].maximum) do nodes[id].maximum = i32(value)
}

successor :: proc "contextless" (nodes: ^[MAX_TREE_NODES]Veb_Node, id: int, value: int) -> i32 {
	if nodes[id].minimum < 0 do return -1
	if value < int(nodes[id].minimum) do return nodes[id].minimum
	if nodes[id].universe == 2 do return if value == 0 && nodes[id].maximum == 1 { 1 } else { -1 }
	low_size := 1 << nodes[id].low_bits
	high := value >> nodes[id].low_bits
	low := value & (low_size - 1)
	cluster := nodes[id].clusters[high]
	if nodes[cluster].minimum >= 0 && low < int(nodes[cluster].maximum) {
		next_low := successor(nodes, cluster, low)
		if next_low < 0 do return -1
		return i32(high*low_size) + next_low
	}
	next_cluster := successor(nodes, nodes[id].summary, high)
	if next_cluster < 0 do return -1
	next_minimum := nodes[nodes[id].clusters[int(next_cluster)]].minimum
	if next_minimum < 0 do return -1
	return next_cluster*i32(low_size) + next_minimum
}

predecessor :: proc "contextless" (nodes: ^[MAX_TREE_NODES]Veb_Node, id: int, value: int) -> i32 {
	if nodes[id].minimum < 0 || value <= int(nodes[id].minimum) do return -1
	if value > int(nodes[id].maximum) do return nodes[id].maximum
	if nodes[id].universe == 2 do return if value == 1 && nodes[id].minimum == 0 { 0 } else { -1 }
	low_size := 1 << nodes[id].low_bits
	high := value >> nodes[id].low_bits
	low := value & (low_size - 1)
	cluster := nodes[id].clusters[high]
	if nodes[cluster].minimum >= 0 && low > int(nodes[cluster].minimum) {
		previous_low := predecessor(nodes, cluster, low)
		if previous_low >= 0 do return i32(high*low_size) + previous_low
	}
	previous_cluster := predecessor(nodes, nodes[id].summary, high)
	if previous_cluster < 0 do return nodes[id].minimum
	previous_maximum := nodes[nodes[id].clusters[int(previous_cluster)]].maximum
	if previous_maximum < 0 do return -1
	return previous_cluster*i32(low_size) + previous_maximum
}

@(export, link_name="veb_tree")
veb_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_VALUES + 1) do return -1
	if input[0] < 2 || input[0] > 256 || input[1] < 0 || input[1] > MAX_COUNT || input[2] < 0 || input[2] > MAX_COUNT do return -1
	requested := int(input[0])
	insert_count := int(input[1])
	query_count := int(input[2])
	if int(length) != 3 + insert_count + 2*query_count do return -1
	for i := 0; i < insert_count; i += 1 {
		if input[3+i] < 0 || input[3+i] >= i64(requested) do return -1
	}
	for i := 0; i < query_count; i += 1 {
		opcode := input[3+insert_count+2*i]
		key := input[4+insert_count+2*i]
		if opcode < 0 || opcode > 4 || key < 0 || key >= i64(requested) do return -1
	}
	needed := query_count * 4
	if needed > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(needed) do return -2

	rounded := 1
	for rounded < requested { rounded *= 2 }
	var nodes: [MAX_TREE_NODES]Veb_Node
	next := 0
	root := initialize(&nodes, &next, rounded)
	for i := 0; i < insert_count; i += 1 { insert(&nodes, root, int(input[3+i])) }
	var result: [MAX_OUTPUT_BYTES]u8
	for i := 0; i < query_count; i += 1 {
		opcode := int(input[3+insert_count+2*i])
		key := int(input[4+insert_count+2*i])
		value: i32 = 0
		if opcode == 0 {
			if contains(&nodes, root, key) { value = 1 }
		} else if opcode == 1 {
			value = successor(&nodes, root, key)
		} else if opcode == 2 {
			value = predecessor(&nodes, root, key)
		} else if opcode == 3 {
			value = nodes[root].minimum
		} else if nodes[root].minimum >= 0 {
			value = nodes[root].maximum
		}
		bits := u32(value)
		result[4*i] = u8(bits)
		result[4*i+1] = u8(bits >> 8)
		result[4*i+2] = u8(bits >> 16)
		result[4*i+3] = u8(bits >> 24)
	}
	for i := 0; i < needed; i += 1 { output[i] = result[i] }
	return i64(needed)
}
