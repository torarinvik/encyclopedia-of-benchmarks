module mst_edge_classification

const max_vertices = 12
const max_edges = 24
const max_input_length = 2 + 3 * max_edges + 1

fn find_root(mut parent []int, vertex int) int {
	mut root := vertex
	for parent[root] != root { root = parent[root] }
	mut current := vertex
	for parent[current] != current {
		next := parent[current]
		parent[current] = root
		current = next
	}
	return root
}

fn join_roots(mut parent []int, left int, right int) {
	a := find_root(mut parent, left)
	b := find_root(mut parent, right)
	if a != b { parent[b] = a }
}

fn alternative_path_exists(left []int, right []int, edge_id []int,
	edge_count int, omitted int, source int, target int) bool {
	mut seen := [max_vertices]bool{}
	mut queue := [max_vertices]int{}
	mut head := 0
	mut tail := 0
	seen[source] = true
	queue[tail] = source
	tail++
	for head < tail {
		vertex := queue[head]
		head++
		if vertex == target { return true }
		for edge in 0 .. edge_count {
			if edge_id[edge] == omitted { continue }
			mut neighbor := -1
			if left[edge] == vertex { neighbor = right[edge] }
			else if right[edge] == vertex { neighbor = left[edge] }
			if neighbor >= 0 && !seen[neighbor] {
				seen[neighbor] = true
				queue[tail] = neighbor
				tail++
			}
		}
	}
	return false
}

@[export: 'mst_edge_classification']
pub fn mst_edge_classification(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		if input[0] < 1 || input[0] > max_vertices || input[1] < 0 || input[1] > max_edges { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if int(length) != 2 + 3 * edge_count { return -1 }
		mut left := [max_edges]int{}
		mut right := [max_edges]int{}
		mut weight := [max_edges]int{}
		mut order := [max_edges]int{}
		mut classes := [max_edges]u8{}
		for edge in 0 .. edge_count {
			u := input[2 + 3 * edge]
			v := input[3 + 3 * edge]
			w := input[4 + 3 * edge]
			if u < 0 || u >= v || v >= i64(vertex_count) || w < 0 || w > 20 { return -1 }
			left[edge] = int(u)
			right[edge] = int(v)
			weight[edge] = int(w)
			order[edge] = edge
			for prior in 0 .. edge {
				if left[prior] == left[edge] && right[prior] == right[edge] { return -1 }
			}
		}
		for i in 1 .. edge_count {
			item := order[i]
			mut j := i
			for j > 0 && (weight[order[j - 1]] > weight[item] ||
					(weight[order[j - 1]] == weight[item] && order[j - 1] > item)) {
				order[j] = order[j - 1]
				j--
			}
			order[j] = item
		}
		mut parent := [max_vertices]int{}
		for vertex in 0 .. vertex_count { parent[vertex] = vertex }
		mut start := 0
		for start < edge_count {
			mut stop := start + 1
			group_weight := weight[order[start]]
			for stop < edge_count && weight[order[stop]] == group_weight { stop++ }
			mut q_left := [max_edges]int{}
			mut q_right := [max_edges]int{}
			mut q_id := [max_edges]int{}
			mut q_count := 0
			for pos in start .. stop {
				id := order[pos]
				a := find_root(mut parent[..vertex_count], left[id])
				b := find_root(mut parent[..vertex_count], right[id])
				if a != b {
					q_left[q_count] = a
					q_right[q_count] = b
					q_id[q_count] = id
					q_count++
				}
			}
			for edge in 0 .. q_count {
				if alternative_path_exists(q_left[..q_count], q_right[..q_count], q_id[..q_count],
						q_count, q_id[edge], q_left[edge], q_right[edge]) {
					classes[q_id[edge]] = 1
				} else {
					classes[q_id[edge]] = 2
				}
			}
			for pos in start .. stop {
				id := order[pos]
				join_roots(mut parent[..vertex_count], left[id], right[id])
			}
			start = stop
		}
		representative := find_root(mut parent[..vertex_count], 0)
		for vertex in 1 .. vertex_count {
			if find_root(mut parent[..vertex_count], vertex) != representative { return -1 }
		}
		if output_capacity < usize(edge_count) || (edge_count > 0 && output == nil) { return -2 }
		for edge in 0 .. edge_count { output[edge] = classes[edge] }
		return i64(edge_count)
	}
}
