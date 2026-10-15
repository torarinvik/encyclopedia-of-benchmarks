module even_tree

@[export: 'even_tree']
pub fn even_tree(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 2 { return invalid }
	n_value, edge_value := values[0], values[1]
	if n_value < 2 || n_value > 100 || n_value % 2 != 0 || edge_value != n_value - 1 { return invalid }
	n, edge_count := int(n_value), int(edge_value)
	if length != usize(2 + 2 * edge_count) { return invalid }
	mut adjacency := [100][100]bool{init: false}
	for i in 0 .. edge_count {
		u_value, v_value := values[2 + 2 * i], values[3 + 2 * i]
		if u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value { return invalid }
		u, v := int(u_value - 1), int(v_value - 1)
		if adjacency[u][v] { return invalid }
		adjacency[u][v] = true
		adjacency[v][u] = true
	}
	mut parents := [100]int{init: -2}
	mut stack := [100]int{init: 0}
	mut order := [100]int{init: 0}
	mut subtree := [100]i64{init: 1}
	parents[0] = -1
	mut top := 1
	mut order_count := 0
	for top > 0 {
		top--
		u := stack[top]
		order[order_count] = u
		order_count++
		for v in 0 .. n {
			if adjacency[u][v] && parents[v] == -2 {
				parents[v] = u
				stack[top] = v
				top++
			}
		}
	}
	if order_count != n { return invalid }
	mut cuts := i64(0)
	mut index := order_count
	for index > 0 {
		index--
		u := order[index]
		if parents[u] >= 0 { subtree[parents[u]] += subtree[u] }
		if subtree[u] % 2 == 0 { cuts++ }
	}
	return cuts - 1
}
