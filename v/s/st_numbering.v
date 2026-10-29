module st_numbering

const max_vertices = 8
const max_edges = 28
const max_arcs = 2 * max_edges
const max_input = 4 + 2 * max_edges

@[export: 'st_numbering']
pub fn st_numbering(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 4 || input_length > max_input { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	s_value := unsafe { input[2] }
	t_value := unsafe { input[3] }
	if n_value < 2 || n_value > max_vertices || m_value < 0 || m_value > max_edges ||
		s_value < 0 || s_value >= n_value || t_value < 0 || t_value >= n_value ||
		s_value == t_value { return -1 }
	n := int(n_value)
	m := int(m_value)
	s := int(s_value)
	t := int(t_value)
	if input_length != usize(4 + 2 * m) { return -1 }

	mut edge_u := [max_edges]int{}
	mut edge_v := [max_edges]int{}
	mut adjacent := [max_vertices]u16{}
	mut st_edge := -1
	for edge in 0 .. m {
		u_value := unsafe { input[4 + 2 * edge] }
		v_value := unsafe { input[5 + 2 * edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		u_bit := u16(1) << u32(v)
		v_bit := u16(1) << u32(u)
		if adjacent[u] & u_bit != 0 { return -1 }
		adjacent[u] |= u_bit
		adjacent[v] |= v_bit
		edge_u[edge] = u
		edge_v[edge] = v
		if (u == s && v == t) || (u == t && v == s) { st_edge = edge }
	}
	if st_edge < 0 { return -1 }

	mut head := [max_vertices]int{}
	for vertex in 0 .. n { head[vertex] = -1 }
	mut arc_to := [max_arcs]int{}
	mut arc_next := [max_arcs]int{}
	mut arc_count := 0
	for edge in 0 .. m {
		if edge == st_edge { continue }
		u := edge_u[edge]
		v := edge_v[edge]
		arc_to[arc_count] = v
		arc_next[arc_count] = head[u]
		head[u] = arc_count
		arc_count++
		arc_to[arc_count] = u
		arc_next[arc_count] = head[v]
		head[v] = arc_count
		arc_count++
	}
	arc_to[arc_count] = t
	arc_next[arc_count] = head[s]
	head[s] = arc_count
	arc_count++
	arc_to[arc_count] = s
	arc_next[arc_count] = head[t]
	head[t] = arc_count

	mut parent := [max_vertices]int{}
	mut discovery := [max_vertices]int{}
	mut low_vertex := [max_vertices]int{}
	mut children := [max_vertices]int{}
	mut next_arc := [max_vertices]int{}
	mut preorder := [max_vertices]int{}
	for vertex in 0 .. n {
		parent[vertex] = -1
		low_vertex[vertex] = vertex
		next_arc[vertex] = -1
	}
	mut stack := [max_vertices]int{}
	mut top := 0
	mut clock := 1
	mut preorder_count := 1
	discovery[s] = clock
	preorder[0] = s
	next_arc[s] = head[s]
	stack[top] = s
	top++
	for top > 0 {
		vertex := stack[top - 1]
		arc := next_arc[vertex]
		if arc < 0 {
			top--
			ancestor := parent[vertex]
			if ancestor >= 0 && discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]] {
				low_vertex[ancestor] = low_vertex[vertex]
			}
			continue
		}
		next_arc[vertex] = arc_next[arc]
		neighbor := arc_to[arc]
		if neighbor == parent[vertex] { continue }
		if discovery[neighbor] == 0 {
			parent[neighbor] = vertex
			children[vertex]++
			clock++
			discovery[neighbor] = clock
			low_vertex[neighbor] = neighbor
			preorder[preorder_count] = neighbor
			preorder_count++
			next_arc[neighbor] = head[neighbor]
			stack[top] = neighbor
			top++
		} else if discovery[neighbor] < discovery[vertex] && discovery[neighbor] < discovery[low_vertex[vertex]] {
			low_vertex[vertex] = neighbor
		}
	}
	if preorder_count != n || children[s] != 1 { return -1 }
	for vertex in 0 .. n {
		if vertex == s { continue }
		for child in 0 .. n {
			if parent[child] == vertex && discovery[low_vertex[child]] >= discovery[vertex] { return -1 }
		}
	}

	mut previous := [max_vertices]int{}
	mut following := [max_vertices]int{}
	mut sign := [max_vertices]int{}
	for vertex in 0 .. n { previous[vertex] = -1; following[vertex] = -1 }
	sign[s] = -1
	following[s] = t
	previous[t] = s
	mut list_head := s
	for order in 2 .. n {
		vertex := preorder[order]
		ancestor := parent[vertex]
		if sign[low_vertex[vertex]] == -1 {
			left := previous[ancestor]
			previous[vertex] = left
			following[vertex] = ancestor
			previous[ancestor] = vertex
			if left >= 0 { following[left] = vertex } else { list_head = vertex }
			sign[ancestor] = 1
		} else {
			right := following[ancestor]
			previous[vertex] = ancestor
			following[vertex] = right
			following[ancestor] = vertex
			if right >= 0 { previous[right] = vertex }
			sign[ancestor] = -1
		}
	}

	mut rank := [max_vertices]int{}
	mut staged := [max_vertices]u8{}
	mut rank_value := 1
	mut vertex := list_head
	for vertex >= 0 && rank_value <= n {
		rank[vertex] = rank_value
		staged[vertex] = u8(rank_value)
		rank_value++
		vertex = following[vertex]
	}
	if rank_value != n + 1 || rank[s] != 1 || rank[t] != n { return -1 }
	for v in 0 .. n {
		if v == s || v == t { continue }
		mut lower := false
		mut higher := false
		mut arc := head[v]
		for arc >= 0 {
			neighbor := arc_to[arc]
			lower = lower || rank[neighbor] < rank[v]
			higher = higher || rank[neighbor] > rank[v]
			arc = arc_next[arc]
		}
		if !lower || !higher { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(n) { return -2 }
	for v in 0 .. n { unsafe { output[v] = staged[v] } }
	return i64(n)
}
