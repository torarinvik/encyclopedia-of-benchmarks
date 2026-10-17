module kruskal_mst

const max_vertices = 64
const max_edges = max_vertices * (max_vertices - 1) / 2
const max_valid_input_length = 2 + 3 * max_edges
const max_input_length = max_valid_input_length + 1
const weight_min = i64(-1000000)
const weight_max = i64(1000000)
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

struct Edge {
	left int
	right int
	weight i32
}

fn sift_down(mut edges [max_edges]Edge, root_arg int, end int) {
	mut root := root_arg
	for root * 2 + 1 < end {
		mut child := root * 2 + 1
		if child + 1 < end && edges[child].weight < edges[child + 1].weight { child++ }
		if edges[root].weight >= edges[child].weight { return }
		edges[root], edges[child] = edges[child], edges[root]
		root = child
	}
}

fn sort_edges(mut edges [max_edges]Edge, count int) {
	mut start := count / 2
	for start > 0 {
		start--
		sift_down(mut edges, start, count)
	}
	mut end := count
	for end > 1 {
		end--
		edges[0], edges[end] = edges[end], edges[0]
		sift_down(mut edges, 0, end)
	}
}

fn find_root(mut parent [max_vertices]int, vertex_arg int) int {
	mut root := vertex_arg
	for parent[root] != root { root = parent[root] }
	mut vertex := vertex_arg
	for parent[vertex] != vertex {
		next := parent[vertex]
		parent[vertex] = root
		vertex = next
	}
	return root
}

fn union_sets(mut parent [max_vertices]int, mut ranks [max_vertices]int, left int, right int) bool {
	left_root := find_root(mut parent, left)
	right_root := find_root(mut parent, right)
	if left_root == right_root { return false }
	if ranks[left_root] < ranks[right_root] { parent[left_root] = right_root }
	else {
		parent[right_root] = left_root
		if ranks[left_root] == ranks[right_root] { ranks[left_root]++ }
	}
	return true
}

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

fn hash_u16(mut hash u64, value u16) u64 {
	for shift in 0 .. 2 { hash = (hash ^ u64(u8(value >> (shift * 8)))) * fnv_prime }
	return hash
}

fn hash_i32(mut hash u64, value i32) u64 {
	bits := u32(value)
	for shift in 0 .. 4 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'kruskal_mst']
pub fn kruskal_mst(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > i64(max_vertices) || input[1] < 0 || input[1] > i64(max_edges) { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if length != usize(2 + 3 * edge_count) || length > usize(max_valid_input_length) { return -1 }
		maximum_for_graph := vertex_count * (vertex_count - 1) / 2
		if edge_count > maximum_for_graph || (vertex_count == 1 && edge_count != 0) ||
			(vertex_count > 1 && edge_count < vertex_count - 1) { return -1 }

		mut edges := [max_edges]Edge{}
		mut seen_pairs := [max_vertices * max_vertices]bool{}
		for index in 0 .. edge_count {
			offset := 2 + 3 * index
			raw_left := input[offset]
			raw_right := input[offset + 1]
			raw_weight := input[offset + 2]
			if raw_left < 0 || raw_left >= i64(vertex_count) || raw_right < 0 || raw_right >= i64(vertex_count) ||
				raw_left == raw_right || raw_weight < weight_min || raw_weight > weight_max { return -1 }
			left := int(raw_left)
			right := int(raw_right)
			lower := if left < right { left } else { right }
			upper := if left < right { right } else { left }
			pair_index := lower * max_vertices + upper
			if seen_pairs[pair_index] { return -1 }
			seen_pairs[pair_index] = true
			edges[index] = Edge{left: lower, right: upper, weight: i32(raw_weight)}
		}
		sort_edges(mut edges, edge_count)
		if edge_count > 1 {
			for index in 1 .. edge_count {
				if edges[index - 1].weight == edges[index].weight { return -1 }
			}
		}

		mut parent := [max_vertices]int{}
		mut ranks := [max_vertices]int{}
		for vertex in 0 .. vertex_count { parent[vertex] = vertex }
		mut accepted := [max_vertices - 1]Edge{}
		mut accepted_count := 0
		mut total_weight := i64(0)
		for index in 0 .. edge_count {
			if accepted_count == vertex_count - 1 { break }
			if union_sets(mut parent, mut ranks, edges[index].left, edges[index].right) {
				accepted[accepted_count] = edges[index]
				accepted_count++
				total_weight += i64(edges[index].weight)
			}
		}
		if accepted_count != vertex_count - 1 { return -1 }

		mut hash := fnv_offset
		hash = hash_u16(mut hash, u16(vertex_count))
		hash = hash_u16(mut hash, u16(accepted_count))
		for index in 0 .. accepted_count {
			hash = hash_u16(mut hash, u16(accepted[index].left))
			hash = hash_u16(mut hash, u16(accepted[index].right))
			hash = hash_i32(mut hash, accepted[index].weight)
		}
		hash = hash_i64(mut hash, total_weight)
		return i64(hash & u64(0x7fffffffffffffff))
	}
}
