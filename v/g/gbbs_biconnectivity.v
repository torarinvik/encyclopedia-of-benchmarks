// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
const gbbs_bc_n = 12
const gbbs_bc_m = 24
const gbbs_bc_max_input = 50

fn tree_edge(u int, v int, parent []int) bool {
	return parent[u] == v || parent[v] == u
}

fn critical_edge(u int, v int, parent []int, critical []bool) bool {
	if parent[u] == v { return critical[u] }
	if parent[v] == u { return critical[v] }
	return false
}

fn parents_bfs(n int, adjacent [][]bool, mut parent []int, mut seen []bool) {
	mut frontier := []int{len: gbbs_bc_n, init: 0}
	mut following := []int{len: gbbs_bc_n, init: 0}
	mut candidate := []int{len: gbbs_bc_n, init: 0}
	for root in 0 .. n {
		if seen[root] { continue }
		mut count := 1
		frontier[0] = root
		parent[root] = root
		seen[root] = true
		for count != 0 {
			mut has := []bool{len: gbbs_bc_n, init: false}
			for i in 0 .. count {
				vertex := frontier[i]
				for other in 0 .. n {
					if adjacent[vertex][other] && !seen[other] {
						if !has[other] || vertex < candidate[other] {
							candidate[other] = vertex
						}
						has[other] = true
					}
				}
			}
			mut next_count := 0
			for other in 0 .. n {
				if has[other] {
					parent[other] = candidate[other]
					seen[other] = true
					following[next_count] = other
					next_count++
				}
			}
			for i in 0 .. next_count { frontier[i] = following[i] }
			count = next_count
		}
	}
}

fn assign_preorder(n int, parent []int, mut pn []int, mut order []int, mut subtree_size []int) {
	mut stack := []int{len: gbbs_bc_n, init: 0}
	mut global := 0
	for root in 0 .. n {
		if parent[root] != root { continue }
		mut top := 0
		mut count := 0
		begin := global
		stack[top] = root
		top++
		for top != 0 {
			top--
			vertex := stack[top]
			pn[vertex] = count
			count++
			order[global] = vertex
			global++
			for child := n - 1; child >= 0; child-- {
				if child != vertex && parent[child] == vertex {
					stack[top] = child
					top++
				}
			}
		}
		mut i := global
		for i > begin {
			i--
			vertex := order[i]
			if parent[vertex] != vertex {
				subtree_size[parent[vertex]] += subtree_size[vertex]
			}
		}
	}
}

@[export: 'gbbs_biconnectivity']
pub fn gbbs_biconnectivity(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > gbbs_bc_max_input { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > gbbs_bc_n || m64 < 0 || m64 > gbbs_bc_m ||
			length != usize(2 + 2 * m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: gbbs_bc_n, init: []bool{len: gbbs_bc_n, init: false}}
		for edge in 0 .. m {
			u64 := input[2 + 2 * edge]
			v64 := input[3 + 2 * edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
		}
		if output == nil || capacity < usize(m) { return -2 }
		mut parent := []int{len: gbbs_bc_n, init: 0}
		mut pn := []int{len: gbbs_bc_n, init: 0}
		mut order := []int{len: gbbs_bc_n, init: 0}
		mut subtree_size := []int{len: gbbs_bc_n, init: 1}
		mut seen := []bool{len: gbbs_bc_n, init: false}
		mut critical := []bool{len: gbbs_bc_n, init: false}
		for v in 0 .. n { parent[v] = v }
		parents_bfs(n, adjacent, mut parent, mut seen)
		assign_preorder(n, parent, mut pn, mut order, mut subtree_size)
		mut low := pn.clone()
		mut high := []int{len: gbbs_bc_n, init: 0}
		for v in 0 .. n { high[v] = pn[v] + subtree_size[v] - 1 }
		for edge in 0 .. m {
			u := int(input[2 + 2 * edge])
			v := int(input[3 + 2 * edge])
			if !tree_edge(u, v, parent) {
				if pn[u] < low[v] { low[v] = pn[u] } else if pn[u] > high[v] { high[v] = pn[u] }
				if pn[v] < low[u] { low[u] = pn[v] } else if pn[v] > high[u] { high[u] = pn[v] }
			}
		}
		for i := n - 1; i >= 0; i-- {
			vertex := order[i]
			if parent[vertex] != vertex {
				p := parent[vertex]
				low[p] = min(low[p], low[vertex])
				high[p] = max(high[p], high[vertex])
			}
		}
		for v in 0 .. n {
			p := parent[v]
			if v != p && low[v] >= pn[p] && high[v] < pn[p] + subtree_size[p] {
				critical[v] = true
			}
		}
		mut component := []int{len: gbbs_bc_n, init: gbbs_bc_n}
		mut queue := []int{len: gbbs_bc_n, init: 0}
		for root in 0 .. n {
			if component[root] != gbbs_bc_n { continue }
			mut head := 0
			mut tail := 0
			component[root] = root
			queue[tail] = root
			tail++
			for head < tail {
				vertex := queue[head]
				head++
				for other in 0 .. n {
					if adjacent[vertex][other] && !critical_edge(vertex, other, parent, critical) &&
						component[other] == gbbs_bc_n {
						component[other] = root
						queue[tail] = other
						tail++
					}
				}
			}
		}
		mut raw := []int{len: gbbs_bc_m, init: 0}
		for edge in 0 .. m {
			u := int(input[2 + 2 * edge])
			v := int(input[3 + 2 * edge])
			if parent[u] == v && critical[u] { raw[edge] = component[u] }
			else if parent[v] == u && critical[v] { raw[edge] = component[v] }
			else { raw[edge] = component[u] }
		}
		for edge in 0 .. m {
			mut label := m
			for other in 0 .. m {
				if raw[other] == raw[edge] { label = min(label, other) }
			}
			output[edge] = u8(label)
		}
		return i64(m)
	}
}
