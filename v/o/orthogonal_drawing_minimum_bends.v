module orthogonal_drawing_minimum_bends

const nmax = 8
const mmax = 16
const fmax = 10
const input_max = 79
const node_max = 20
const edge_max = 200
const inf = i64(1) << 60

struct BendEdge {
	from_node int
	to_node int
	reverse_index int
	capacity i64
	cost i64
}

fn bend_connected(adjacency [][]bool, n int, removed int) bool {
	start := if removed == 0 { 1 } else { 0 }
	mut seen := []bool{len: nmax, init: false}
	mut stack := []int{len: nmax, init: 0}
	mut top := 1
	mut count := 0
	seen[start] = true
	stack[0] = start
	for top > 0 {
		top--
		u := stack[top]
		count++
		for v in 0 .. n {
			if v != removed && adjacency[u][v] && !seen[v] {
				seen[v] = true
				stack[top] = v
				top++
			}
		}
	}
	expected := n
	if removed >= 0 { expected-- }
	return count == expected
}

fn bend_add_arc(mut edges []BendEdge, mut count int, u int, v int, capacity i64, cost i64) bool {
	if count + 2 > edge_max { return false }
	e := count
	edges[e] = BendEdge{from_node: u, to_node: v, reverse_index: e + 1, capacity: capacity, cost: cost}
	edges[e + 1] = BendEdge{from_node: v, to_node: u, reverse_index: e, capacity: 0, cost: -cost}
	count += 2
	return true
}

@[export: 'orthogonal_drawing_minimum_bends']
pub fn orthogonal_drawing_minimum_bends(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > input_max { return -1 }
		n0 := input[0]
		m0 := input[1]
		f0 := input[2]
		outer0 := input[3]
		if n0 < 3 || n0 > nmax || m0 < n0 || m0 > mmax || f0 < 2 || f0 > fmax || f0 != m0 - n0 + 2 || outer0 < 0 || outer0 >= f0 { return -1 }
		n := int(n0)
		m := int(m0)
		f := int(f0)
		outer := int(outer0)
		mut adjacency := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		mut degree := []int{len: nmax, init: 0}
		mut edge_u := []int{len: mmax, init: 0}
		mut edge_v := []int{len: mmax, init: 0}
		mut uses := [][]int{len: nmax, init: []int{len: nmax, init: 0}}
		mut cursor := 4
		for e in 0 .. m {
			if cursor + 2 > int(input_length) { return -1 }
			u0 := input[cursor]
			v0 := input[cursor + 1]
			cursor += 2
			if u0 < 0 || u0 >= v0 || v0 >= n0 { return -1 }
			u := int(u0)
			v := int(v0)
			if adjacency[u][v] || (e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1]))) { return -1 }
			adjacency[u][v] = true
			adjacency[v][u] = true
			degree[u]++
			degree[v]++
			edge_u[e] = u
			edge_v[e] = v
		}
		for v in 0 .. n { if degree[v] < 2 || degree[v] > 4 { return -1 } }
		mut faces := [][]int{len: fmax, init: []int{len: nmax, init: 0}}
		mut widths := []int{len: fmax, init: 0}
		mut link_adj := []bool{len: nmax * nmax * nmax, init: false}
		mut link_degree := []int{len: nmax * nmax, init: 0}
		for face in 0 .. f {
			if cursor >= int(input_length) { return -1 }
			width0 := input[cursor]
			cursor++
			if width0 < 3 || width0 > n0 || cursor + int(width0) > int(input_length) { return -1 }
			width := int(width0)
			widths[face] = width
			mut row_seen := []bool{len: nmax, init: false}
			for i in 0 .. width {
				vertex0 := input[cursor]
				cursor++
				if vertex0 < 0 || vertex0 >= n0 { return -1 }
				vertex := int(vertex0)
				if row_seen[vertex] { return -1 }
				row_seen[vertex] = true
				faces[face][i] = vertex
			}
			for i in 0 .. width {
				u := faces[face][i]
				v := faces[face][(i + 1) % width]
				if !adjacency[u][v] { return -1 }
				uses[u][v]++
			}
			for i in 0 .. width {
				center := faces[face][i]
				before := faces[face][(i + width - 1) % width]
				after := faces[face][(i + 1) % width]
				if before == after { return -1 }
				link_adj[center * nmax * nmax + before * nmax + after] = true
				link_adj[center * nmax * nmax + after * nmax + before] = true
				link_degree[center * nmax + before]++
				link_degree[center * nmax + after]++
			}
		}
		if cursor != int(input_length) || n - m + f != 2 || !bend_connected(adjacency, n, -1) { return -1 }
		for v in 0 .. n { if !bend_connected(adjacency, n, v) { return -1 } }
		for e in 0 .. m { if uses[edge_u[e]][edge_v[e]] != 1 || uses[edge_v[e]][edge_u[e]] != 1 { return -1 } }
		for center in 0 .. n {
			mut start := -1
			mut incident_count := 0
			for neighbor in 0 .. n {
				if adjacency[center][neighbor] {
					if link_degree[center * nmax + neighbor] != 2 { return -1 }
					if start < 0 { start = neighbor }
					incident_count++
				} else if link_degree[center * nmax + neighbor] != 0 { return -1 }
			}
			mut seen := []bool{len: nmax, init: false}
			mut stack := []int{len: nmax, init: 0}
			mut top := 1
			mut reached := 0
			seen[start] = true
			stack[0] = start
			for top > 0 {
				top--
				neighbor := stack[top]
				reached++
				for other in 0 .. n {
					if link_adj[center * nmax * nmax + neighbor * nmax + other] && !seen[other] {
						seen[other] = true
						stack[top] = other
						top++
					}
				}
			}
			if reached != incident_count { return -1 }
		}
		mut face_a := []int{len: mmax, init: 0}
		mut face_b := []int{len: mmax, init: 0}
		mut face_use := []int{len: mmax, init: 0}
		for face in 0 .. f {
			for i in 0 .. widths[face] {
				u := faces[face][i]
				v := faces[face][(i + 1) % widths[face]]
				lo := if u < v { u } else { v }
				hi := if u < v { v } else { u }
				mut found := -1
				for e in 0 .. m { if edge_u[e] == lo && edge_v[e] == hi { found = e; break } }
				if found < 0 || face_use[found] >= 2 { return -1 }
				if face_use[found] == 0 { face_a[found] = face } else { face_b[found] = face }
				face_use[found]++
			}
		}
		for e in 0 .. m { if face_use[e] != 2 || face_a[e] == face_b[e] { return -1 } }
		if output == nil || output_capacity < 8 { return -2 }
		base := n + f
		source := base
		sink := base + 1
		nodes := base + 2
		mut edges := []BendEdge{len: edge_max, init: BendEdge{}}
		mut edge_count := 0
		mut balance := []i64{len: nmax + fmax, init: 0}
		for v in 0 .. n { balance[v] = 4 }
		for face in 0 .. f {
			d := i64(widths[face])
			face_offset := -4
			if face == outer { face_offset = 4 }
			balance[n + face] -= 2 * d + i64(face_offset)
			for i in 0 .. widths[face] {
				v := faces[face][i]
				balance[v]--
				balance[n + face]++
				if !bend_add_arc(mut edges, mut edge_count, v, n + face, 4 * i64(n), 0) { return -1 }
			}
		}
		for e in 0 .. m {
			if !bend_add_arc(mut edges, mut edge_count, n + face_a[e], n + face_b[e], 4 * i64(n), 1) ||
				!bend_add_arc(mut edges, mut edge_count, n + face_b[e], n + face_a[e], 4 * i64(n), 1) { return -1 }
		}
		mut required := i64(0)
		for v in 0 .. base {
			if balance[v] > 0 {
				if !bend_add_arc(mut edges, mut edge_count, source, v, balance[v], 0) { return -1 }
				required += balance[v]
			} else if balance[v] < 0 && !bend_add_arc(mut edges, mut edge_count, v, sink, -balance[v], 0) { return -1 }
		}
		mut potential := []i64{len: node_max, init: 0}
		mut total_flow := i64(0)
		mut total_cost := i64(0)
		for total_flow < required {
			mut dist := []i64{len: node_max, init: inf}
			mut parent := []int{len: node_max, init: -1}
			mut used := []bool{len: node_max, init: false}
			dist[source] = 0
			for _ in 0 .. nodes {
				mut chosen := -1
				for v in 0 .. nodes { if !used[v] && dist[v] != inf && (chosen < 0 || dist[v] < dist[chosen]) { chosen = v } }
				if chosen < 0 { break }
				used[chosen] = true
				for e in 0 .. edge_count {
					if edges[e].from_node != chosen || edges[e].capacity <= 0 { continue }
					v := edges[e].to_node
					candidate := dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
					if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e }
				}
			}
			if dist[sink] == inf { return -1 }
			for v in 0 .. nodes { if dist[v] != inf { potential[v] += dist[v] } }
			mut amount := required - total_flow
			mut path_cost := i64(0)
			mut vertex := sink
			for vertex != source {
				e := parent[vertex]
				if e < 0 { return -1 }
				if amount > edges[e].capacity { amount = edges[e].capacity }
				path_cost += edges[e].cost
				vertex = edges[e].from_node
			}
			vertex = sink
			for vertex != source {
				e := parent[vertex]
				edges[e].capacity -= amount
				edges[edges[e].reverse_index].capacity += amount
				vertex = edges[e].from_node
			}
			total_flow += amount
			total_cost += amount * path_cost
		}
		bits := u64(total_cost)
		for i in 0 .. 8 { output[i] = u8(bits >> (8 * i)) }
		return 8
	}
}
