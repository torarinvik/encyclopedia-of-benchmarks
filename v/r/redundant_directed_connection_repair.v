module redundant_directed_connection_repair

const max_n = 16

fn repair_find(mut parent []int, node_input int) int {
	mut node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

@[export: 'redundant_directed_connection_repair']
pub fn redundant_directed_connection_repair(input &i64, length usize) i64 {
	if length < 1 || length > 34 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		if n_value < 3 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 2*n) { return -1 }
		mut from := []int{len: n, cap: n}
		mut to := []int{len: n, cap: n}
		mut incoming := []int{len: max_n, cap: max_n, init: -1}
		mut parent := []int{len: max_n, cap: max_n}
		mut sizes := []int{len: max_n, cap: max_n, init: 1}
		for node in 0 .. n { parent[node] = node }
		for edge in 0 .. n {
			u, v := input[1+2*edge], input[2+2*edge]
			if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v { return -1 }
			from[edge], to[edge] = int(u), int(v)
			for prior in 0 .. edge {
				if from[prior] == from[edge] && to[prior] == to[edge] { return -1 }
			}
		}
		mut first_parent := -1
		mut second_parent := -1
		for edge in 0 .. n {
			child := to[edge]
			if incoming[child] < 0 { incoming[child] = edge }
			else { first_parent = incoming[child]; second_parent = edge; break }
		}
		mut cycle_edge := -1
		for edge in 0 .. n {
			if edge == second_parent { continue }
			mut a := repair_find(mut parent, from[edge])
			mut b := repair_find(mut parent, to[edge])
			if a == b { cycle_edge = edge; break }
			if sizes[a] < sizes[b] { a, b = b, a }
			parent[b] = a
			sizes[a] += sizes[b]
		}
		if cycle_edge >= 0 {
			if second_parent >= 0 { return first_parent }
			return cycle_edge
		}
		return second_parent
	}
}
