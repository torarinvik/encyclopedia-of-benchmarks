module matroid_intersection

const max_vertices = 10
const max_edges = 20
const max_colors = 8

fn mi_is_forest(input &i64, vertices int, edges int, edge_start int,
	chosen [20]bool, removed i64, added i64) bool {
	unsafe {
		mut parent := [10]i64{}
		for vertex in 0 .. vertices { parent[vertex] = i64(vertex) }
		for edge in 0 .. edges {
			if i64(edge) != added && (!chosen[edge] || i64(edge) == removed) { continue }
			mut a := int(input[edge_start + 3*edge])
			mut b := int(input[edge_start + 3*edge + 1])
			for parent[a] != i64(a) { a = int(parent[a]) }
			for parent[b] != i64(b) { b = int(parent[b]) }
			if a == b { return false }
			parent[b] = i64(a)
		}
		return true
	}
}

fn mi_within_quotas(input &i64, colors int, edges int, edge_start int,
	chosen [20]bool, removed i64, added i64) bool {
	unsafe {
		mut counts := [8]i64{}
		for edge in 0 .. edges {
			if i64(edge) != added && (!chosen[edge] || i64(edge) == removed) { continue }
			color := int(input[edge_start + 3*edge + 2])
			counts[color]++
			if counts[color] > input[3 + color] { return false }
		}
		return true
	}
}

@[export: 'matroid_intersection']
pub fn matroid_intersection(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 72 { return -1 }
		vertices_value := input[0]
		edges_value := input[1]
		colors_value := input[2]
		if vertices_value < 1 || vertices_value > max_vertices || edges_value < 0 || edges_value > max_edges
			|| colors_value < 1 || colors_value > max_colors { return -1 }
		vertices := int(vertices_value)
		edges := int(edges_value)
		colors := int(colors_value)
		if length != usize(3 + colors + 3*edges) { return -1 }
		for color in 0 .. colors {
			if input[3 + color] < 0 || input[3 + color] > max_edges { return -1 }
		}
		edge_start := 3 + colors
		for edge in 0 .. edges {
			u := input[edge_start + 3*edge]
			v := input[edge_start + 3*edge + 1]
			color := input[edge_start + 3*edge + 2]
			if u < 0 || u >= vertices_value || v < 0 || v >= vertices_value || color < 0 || color >= colors_value { return -1 }
		}

		mut chosen := [20]bool{}
		for {
			mut predecessor := [20]i64{}
			for edge in 0 .. edges { predecessor[edge] = -2 }
			mut queue := [20]i64{}
			mut head := 0
			mut tail := 0
			for edge in 0 .. edges {
				if !chosen[edge] && mi_is_forest(input, vertices, edges, edge_start, chosen, -1, i64(edge)) {
					predecessor[edge] = -1
					queue[tail] = i64(edge)
					tail++
				}
			}
			mut terminal := i64(-1)
			for head < tail && terminal < 0 {
				current := int(queue[head])
				head++
				if !chosen[current] {
					if mi_within_quotas(input, colors, edges, edge_start, chosen, -1, i64(current)) {
						terminal = i64(current)
						break
					}
					for inside in 0 .. edges {
						if chosen[inside] && predecessor[inside] == -2
							&& mi_within_quotas(input, colors, edges, edge_start, chosen, i64(inside), i64(current)) {
							predecessor[inside] = i64(current)
							queue[tail] = i64(inside)
							tail++
						}
					}
				} else {
					for outside in 0 .. edges {
						if !chosen[outside] && predecessor[outside] == -2
							&& mi_is_forest(input, vertices, edges, edge_start, chosen, i64(current), i64(outside)) {
							predecessor[outside] = i64(current)
							queue[tail] = i64(outside)
							tail++
						}
					}
				}
			}
			if terminal < 0 { break }
			mut node := terminal
			for node >= 0 {
				index := int(node)
				chosen[index] = !chosen[index]
				node = predecessor[index]
			}
		}
		mut answer := i64(0)
		for edge in 0 .. edges { if chosen[edge] { answer++ } }
		return answer
	}
}
