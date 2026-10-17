module minimum_spanning_tree_kruskal2

const max_vertices = 16
const max_edges = 64
const max_input_words = 194
const max_output_words = 1 + 3 * (max_vertices - 1)
const max_output_bytes = 4 * max_output_words

struct Edge {
	u       i32
	v       i32
	weight  i32
}

fn find_root(mut parent [max_vertices]int, node int) int {
	mut current := node
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'minimum_spanning_tree_kruskal2']
pub fn minimum_spanning_tree_kruskal2(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_words) { return -1 }
		vertex_count := input[0]
		edge_count := input[1]
		if vertex_count < 1 || vertex_count > max_vertices || edge_count < 0 || edge_count > max_edges { return -1 }
		if length != usize(2 + 3 * edge_count) { return -1 }
		mut input_edges := [max_edges]Edge{}
		mut seen := [max_vertices][max_vertices]bool{}
		mut pos := 2
		for i in 0 .. int(edge_count) {
			u := input[pos]
			v := input[pos + 1]
			weight := input[pos + 2]
			pos += 3
			if u < 0 || v <= u || v >= vertex_count || seen[u][v] { return -1 }
			seen[u][v] = true
			input_edges[i] = Edge{u: u, v: v, weight: weight}
		}

		mut visited := [max_vertices]bool{}
		mut stack := [max_vertices]int{}
		mut stack_size := 1
		mut reached := 0
		stack[0] = 0
		visited[0] = true
		for stack_size > 0 {
			stack_size--
			node := stack[stack_size]
			reached++
			for neighbor in 0 .. int(vertex_count) {
				if (seen[node][neighbor] || seen[neighbor][node]) && !visited[neighbor] {
					visited[neighbor] = true
					stack[stack_size] = neighbor
					stack_size++
				}
			}
		}
		if reached != int(vertex_count) { return -1 }

		mut ordered := [max_edges]Edge{}
		mut ordered_count := 0
		for u in 0 .. int(vertex_count) {
			for i in 0 .. int(edge_count) {
				if input_edges[i].u == i32(u) {
					ordered[ordered_count] = input_edges[i]
					ordered_count++
				}
			}
		}
		for i in 1 .. ordered_count {
			key := ordered[i]
			mut j := i
			for j > 0 && ordered[j - 1].weight > key.weight {
				ordered[j] = ordered[j - 1]
				j--
			}
			ordered[j] = key
		}

		mut parent := [max_vertices]int{}
		mut ranks := [max_vertices]int{}
		for i in 0 .. int(vertex_count) { parent[i] = i }
		mut words := [max_output_words]i32{}
		mut word_count := 1
		mut accepted := 0
		for i in 0 .. ordered_count {
			if accepted == int(vertex_count - 1) { break }
			root_u := find_root(mut parent, int(ordered[i].u))
			root_v := find_root(mut parent, int(ordered[i].v))
			if root_u == root_v { continue }
			if ranks[root_u] < ranks[root_v] { parent[root_u] = root_v }
			else if ranks[root_u] > ranks[root_v] { parent[root_v] = root_u }
			else { parent[root_u] = root_v; ranks[root_v]++ }
			words[word_count] = ordered[i].u
			words[word_count + 1] = ordered[i].v
			words[word_count + 2] = ordered[i].weight
			word_count += 3
			accepted++
		}
		if accepted != int(vertex_count - 1) { return -1 }
		words[0] = i32(accepted)
		bytes := word_count * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. word_count { put_i32_le(mut buffer[0], i * 4, words[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
