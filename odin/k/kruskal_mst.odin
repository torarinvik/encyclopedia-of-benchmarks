package kruskal_mst

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: MAX_VERTICES * (MAX_VERTICES - 1) / 2
MAX_VALID_INPUT_LENGTH :: 2 + 3 * MAX_EDGES
MAX_INPUT_LENGTH :: MAX_VALID_INPUT_LENGTH + 1
WEIGHT_MIN :: i64(-1_000_000)
WEIGHT_MAX :: i64(1_000_000)
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

Edge :: struct { left, right: int, weight: i32 }

sift_down :: proc "contextless" (edges: [^]Edge, root_arg, end_exclusive: int) {
	root := root_arg
	for root * 2 + 1 < end_exclusive {
		child := root * 2 + 1
		if child + 1 < end_exclusive && edges[child].weight < edges[child + 1].weight { child += 1 }
		if edges[root].weight >= edges[child].weight do return
		edges[root], edges[child] = edges[child], edges[root]
		root = child
	}
}

sort_edges :: proc "contextless" (edges: [^]Edge, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(edges, start, count)
	}
	end_exclusive := count
	for end_exclusive > 1 {
		end_exclusive -= 1
		edges[0], edges[end_exclusive] = edges[end_exclusive], edges[0]
		sift_down(edges, 0, end_exclusive)
	}
}

find_root :: proc "contextless" (parent: [^]int, vertex_arg: int) -> int {
	root := vertex_arg
	for parent[root] != root { root = parent[root] }
	vertex := vertex_arg
	for parent[vertex] != vertex {
		next := parent[vertex]
		parent[vertex] = root
		vertex = next
	}
	return root
}

union_sets :: proc "contextless" (parent, ranks: [^]int, left, right: int) -> bool {
	left_root := find_root(parent, left)
	right_root := find_root(parent, right)
	if left_root == right_root do return false
	if ranks[left_root] < ranks[right_root] { parent[left_root] = right_root }
	else {
		parent[right_root] = left_root
		if ranks[left_root] == ranks[right_root] { ranks[left_root] += 1 }
	}
	return true
}

hash_byte :: proc "contextless" (hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_u16 :: proc "contextless" (hash_arg: u64, value: u16) -> u64 {
	hash := hash_arg
	for byte := 0; byte < 2; byte += 1 {
		hash = hash_byte(hash, u8(value >> u32(byte * 8)))
	}
	return hash
}

hash_i32 :: proc "contextless" (hash_arg: u64, value: i32) -> u64 {
	hash := hash_arg
	bits := transmute(u32(value))
	for byte := 0; byte < 4; byte += 1 {
		hash = hash_byte(hash, u8(bits >> u32(byte * 8)))
	}
	return hash
}

hash_i64 :: proc "contextless" (hash_arg: u64, value: i64) -> u64 {
	hash := hash_arg
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		hash = hash_byte(hash, u8(bits >> u32(byte * 8)))
	}
	return hash
}

kruskal_mst :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	vertex_count64, edge_count64 := input[0], input[1]
	if vertex_count64 < 1 || vertex_count64 > MAX_VERTICES || edge_count64 < 0 || edge_count64 > MAX_EDGES do return -1
	vertex_count, edge_count := int(vertex_count64), int(edge_count64)
	if length != c.size_t(2 + 3 * edge_count) || length > MAX_VALID_INPUT_LENGTH do return -1
	maximum_for_graph := vertex_count * (vertex_count - 1) / 2
	if edge_count > maximum_for_graph || (vertex_count == 1 && edge_count != 0) ||
		(vertex_count > 1 && edge_count < vertex_count - 1) do return -1

	var edges: [MAX_EDGES]Edge
	var seen_pairs: [MAX_VERTICES * MAX_VERTICES]bool
	for index := 0; index < edge_count; index += 1 {
		offset := 2 + 3 * index
		raw_left, raw_right, raw_weight := input[offset], input[offset+1], input[offset+2]
		if raw_left < 0 || raw_left >= vertex_count64 || raw_right < 0 || raw_right >= vertex_count64 ||
			raw_left == raw_right || raw_weight < WEIGHT_MIN || raw_weight > WEIGHT_MAX do return -1
		left, right := int(raw_left), int(raw_right)
		lower, upper := left, right
		if lower > upper { lower, upper = upper, lower }
		pair_index := lower * MAX_VERTICES + upper
		if seen_pairs[pair_index] do return -1
		seen_pairs[pair_index] = true
		edges[index] = Edge{lower, upper, i32(raw_weight)}
	}

	sort_edges(&edges[0], edge_count)
	if edge_count > 1 {
		for index := 1; index < edge_count; index += 1 {
			if edges[index-1].weight == edges[index].weight do return -1
		}
	}

	var parent: [MAX_VERTICES]int
	var ranks: [MAX_VERTICES]int
	for vertex := 0; vertex < vertex_count; vertex += 1 { parent[vertex] = vertex }
	var accepted: [MAX_VERTICES-1]Edge
	accepted_count := 0
	total_weight := i64(0)
	for index := 0; index < edge_count; index += 1 {
		if accepted_count == vertex_count - 1 do break
		if union_sets(&parent[0], &ranks[0], edges[index].left, edges[index].right) {
			accepted[accepted_count] = edges[index]
			accepted_count += 1
			total_weight += i64(edges[index].weight)
		}
	}
	if accepted_count != vertex_count - 1 do return -1

	hash := FNV_OFFSET
	hash = hash_u16(hash, u16(vertex_count))
	hash = hash_u16(hash, u16(accepted_count))
	for index := 0; index < accepted_count; index += 1 {
		hash = hash_u16(hash, u16(accepted[index].left))
		hash = hash_u16(hash, u16(accepted[index].right))
		hash = hash_i32(hash, accepted[index].weight)
	}
	hash = hash_i64(hash, total_weight)
	return i64(hash & 0x7fffffffffffffff)
}
