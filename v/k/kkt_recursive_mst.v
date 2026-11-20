module kkt_recursive_mst

const max_n = 16
const max_m = 16
const max_input = 52

struct KktEdge {
	u int
	v int
	weight i64
	id int
}

fn edge_less(a KktEdge, b KktEdge) bool {
	if a.weight != b.weight { return a.weight < b.weight }
	return a.id < b.id
}

fn next_splitmix(mut state &u64) u64 {
	unsafe { state[0] = state[0] +% u64(0x9E3779B97F4A7C15) }
	mut value := unsafe { state[0] }
	value = (value ^ (value >> 30)) *% u64(0xBF58476D1CE4E5B9)
	value = (value ^ (value >> 27)) *% u64(0x94D049BB133111EB)
	return value ^ (value >> 31)
}

fn dsu_root(mut parent [16]int, node0 int) int {
	mut node := node0
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn sort_edges(mut edges [16]KktEdge, count int) {
	for i in 1 .. count {
		key := edges[i]
		mut position := i
		for position > 0 && edge_less(key, edges[position - 1]) {
			edges[position] = edges[position - 1]
			position--
		}
		edges[position] = key
	}
}

fn boruvka_phase(mut n int, mut edges [16]KktEdge, mut edge_count int, mut selected_mask u64) {
	if edge_count == 0 { return }
	mut best := [16]int{}
	for v in 0 .. n { best[v] = -1 }
	for vertex in 0 .. n {
		for index in 0 .. edge_count {
			e := edges[index]
			if e.u != vertex && e.v != vertex { continue }
			if best[vertex] < 0 || edge_less(e, edges[best[vertex]]) { best[vertex] = index }
		}
	}

	mut parent := [16]int{}
	for vertex in 0 .. n { parent[vertex] = vertex }
	for vertex in 0 .. n {
		if best[vertex] < 0 { continue }
		e := edges[best[vertex]]
		selected_mask |= u64(1) << e.id
		a := dsu_root(mut parent, e.u)
		b := dsu_root(mut parent, e.v)
		if a != b { parent[a] = b }
	}

	mut root_to_local := [16]int{}
	for i in 0 .. max_n { root_to_local[i] = -1 }
	mut local_of := [16]int{}
	mut contracted_n := 0
	for vertex in 0 .. n {
		representative := dsu_root(mut parent, vertex)
		if root_to_local[representative] < 0 {
			root_to_local[representative] = contracted_n
			contracted_n++
		}
		local_of[vertex] = root_to_local[representative]
	}

	mut contracted := [16]KktEdge{}
	mut contracted_count := 0
	for index in 0 .. edge_count {
		mut e := edges[index]
		mut a := local_of[e.u]
		mut b := local_of[e.v]
		if a == b { continue }
		if a > b { a, b = b, a }
		e.u = a
		e.v = b
		mut duplicate := -1
		for j in 0 .. contracted_count {
			if contracted[j].u == a && contracted[j].v == b { duplicate = j; break }
		}
		if duplicate >= 0 {
			if edge_less(e, contracted[duplicate]) { contracted[duplicate] = e }
		} else {
			contracted[contracted_count] = e
			contracted_count++
		}
	}
	n = contracted_n
	edge_count = contracted_count
	edges = contracted
}

fn sample_path_max(n int, sample [16]KktEdge, sample_count int, forest_mask u64,
		start int, target int, mut max_weight i64, mut max_id int) bool {
	if start < 0 || start >= n || target < 0 || target >= n { return false }
	mut seen := [16]bool{}
	mut stack := [16]int{}
	mut has_max := [16]bool{}
	mut path_weight := [16]i64{}
	mut path_id := [16]int{}
	mut top := 1
	stack[0] = start
	seen[start] = true
	for top > 0 && !seen[target] {
		top--
		current := stack[top]
		for index in 0 .. sample_count {
			e := sample[index]
			if forest_mask & (u64(1) << e.id) == 0 { continue }
			mut neighbor := -1
			if e.u == current { neighbor = e.v } else if e.v == current { neighbor = e.u }
			if neighbor < 0 || seen[neighbor] { continue }
			seen[neighbor] = true
			stack[top] = neighbor
			top++
			mut maximum_weight := e.weight
			mut maximum_id := e.id
			if has_max[current] {
				maximum_weight = path_weight[current]
				maximum_id = path_id[current]
				if e.weight > maximum_weight || (e.weight == maximum_weight && e.id > maximum_id) {
					maximum_weight = e.weight
					maximum_id = e.id
				}
			}
			has_max[neighbor] = true
			path_weight[neighbor] = maximum_weight
			path_id[neighbor] = maximum_id
		}
	}
	if !seen[target] { return false }
	max_weight = path_weight[target]
	max_id = path_id[target]
	return true
}

fn kkt_recursive(n_start int, edge_count_start int, input_edges [16]KktEdge, mut state &u64) u64 {
	if edge_count_start == 0 { return 0 }
	mut n := n_start
	mut edge_count := edge_count_start
	mut edges := input_edges
	mut selected_mask := u64(0)
	boruvka_phase(mut n, mut edges, mut edge_count, mut selected_mask)
	if edge_count == 0 { return selected_mask }
	boruvka_phase(mut n, mut edges, mut edge_count, mut selected_mask)
	if edge_count == 0 { return selected_mask }
	sort_edges(mut edges, edge_count)

	mut sample := [16]KktEdge{}
	mut sample_count := 0
	for index in 0 .. edge_count {
		if next_splitmix(mut state) & u64(1) != 0 {
			sample[sample_count] = edges[index]
			sample_count++
		}
	}
	forest_mask := kkt_recursive(n, sample_count, sample, mut state)

	mut light := [16]KktEdge{}
	mut light_count := 0
	for index in 0 .. edge_count {
		e := edges[index]
		mut maximum_weight := i64(0)
		mut maximum_id := 0
		connected := sample_path_max(n, sample, sample_count, forest_mask, e.u, e.v, mut maximum_weight, mut maximum_id)
		heavy := connected && (e.weight > maximum_weight || (e.weight == maximum_weight && e.id > maximum_id))
		if !heavy { light[light_count] = e; light_count++ }
	}
	return selected_mask | kkt_recursive(n, light_count, light, mut state)
}

@[export: 'kkt_recursive_mst']
pub fn kkt_recursive_mst(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value, m_value, seed := input[0], input[1], input[2]
		if n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m || seed < 0 { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(3 + 3 * m) { return -1 }
		mut edges := [16]KktEdge{}
		for index in 0 .. m {
			u_value, v_value, weight := input[3 + 3 * index], input[4 + 3 * index], input[5 + 3 * index]
			if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < 0 || weight > 255 { return -1 }
			u, v := int(u_value), int(v_value)
			for previous in 0 .. index {
				if edges[previous].u == u && edges[previous].v == v { return -1 }
			}
			edges[index] = KktEdge{u: u, v: v, weight: weight, id: index}
		}
		mut state := u64(seed)
		return i64(kkt_recursive(n, m, edges, mut state))
	}
}
