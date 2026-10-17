module mcoloring

const max_vertices = 14
const max_parseable_input_length = 17

fn find_root(mut parent [max_vertices]int, vertex_input int) int {
	mut vertex := vertex_input
	for parent[vertex] != vertex {
		parent[vertex] = parent[parent[vertex]]
		vertex = parent[vertex]
	}
	return vertex
}

@[export: 'mcoloring']
pub fn mcoloring(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		n_value, colors_value := input[0], input[1]
		if n_value < 0 || n_value > max_vertices || colors_value < 1 || colors_value > max_vertices { return -1 }
		n := int(n_value)
		if length != usize(n + 2) { return -1 }

		mut masks := [max_vertices]u32{}
		mut parent := [max_vertices]int{}
		valid_mask := if n == 0 { u32(0) } else { (u32(1) << n) - 1 }
		for vertex in 0 .. n {
			raw := input[vertex + 2]
			if raw < 0 || u64(raw) > u64(valid_mask) { return -1 }
			masks[vertex] = u32(raw)
			if masks[vertex] & (u32(1) << vertex) != 0 { return -1 }
			parent[vertex] = vertex
		}
		for vertex in 0 .. n {
			for neighbor in vertex + 1 .. n {
				edge := masks[vertex] & (u32(1) << neighbor) != 0
				if edge != (masks[neighbor] & (u32(1) << vertex) != 0) { return -1 }
				if edge {
					root_a := find_root(mut parent, vertex)
					root_b := find_root(mut parent, neighbor)
					if root_a == root_b { return -1 }
					parent[root_a] = root_b
				}
			}
		}

		mut colors := [max_vertices]int{}
		mut visited := [max_vertices]bool{}
		mut queue := [max_vertices]int{}
		for vertex in 0 .. n { colors[vertex] = 1 }
		mut maximum_color := 1
		for start in 0 .. n {
			if visited[start] { continue }
			mut head, mut tail := 0, 0
			visited[start] = true
			queue[tail] = start
			tail++
			for head < tail {
				vertex := queue[head]
				head++
				for neighbor in 0 .. n {
					if masks[vertex] & (u32(1) << neighbor) == 0 { continue }
					if colors[vertex] == colors[neighbor] { colors[neighbor]++ }
					if colors[vertex] > maximum_color { maximum_color = colors[vertex] }
					if colors[neighbor] > maximum_color { maximum_color = colors[neighbor] }
					if maximum_color > int(colors_value) { return 0 }
					if !visited[neighbor] {
						visited[neighbor] = true
						queue[tail] = neighbor
						tail++
					}
				}
			}
		}
		return 1
	}
}
