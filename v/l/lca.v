module lca

fn find_root(mut parent []int, vertex int) int {
	mut v := vertex
	for parent[v] != v {
		parent[v] = parent[parent[v]]
		v = parent[v]
	}
	return v
}

@[export: 'lca']
pub fn lca(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 129 { return -1 }
	n64 := unsafe { input[0] }
	if n64 < 1 || n64 > 64 { return -1 }
	n := int(n64)
	if length != usize(2 * n + 1) { return -1 }
	mut dsu := []int{len: n}
	mut degree := [64]int{}
	mut adjacency := [64][64]int{}
	for i in 0 .. n { dsu[i] = i }
	mut pos := 1
	for _ in 0 .. n - 1 {
		u64 := unsafe { input[pos] }; v64 := unsafe { input[pos + 1] }
		pos += 2
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 { return -1 }
		u := int(u64); v := int(v64)
		ru := find_root(mut dsu, u); rv := find_root(mut dsu, v)
		if ru == rv { return -1 }
		dsu[ru] = rv
		adjacency[u][degree[u]] = v; degree[u]++
		adjacency[v][degree[v]] = u; degree[v]++
	}
	qa64 := unsafe { input[pos] }; qb64 := unsafe { input[pos + 1] }
	if qa64 < 0 || qa64 >= n64 || qb64 < 0 || qb64 >= n64 { return -1 }
	component := find_root(mut dsu, 0)
	for i in 1 .. n { if find_root(mut dsu, i) != component { return -1 } }
	mut parent := [64]int{}
	mut depth := [64]int{}
	mut stack := [64]int{}
	mut seen := [64]bool{}
	mut stack_size := 1
	stack[0] = 0
	seen[0] = true
	for stack_size > 0 {
		stack_size--
		vertex := stack[stack_size]
		for i in 0 .. degree[vertex] {
			next := adjacency[vertex][i]
			if !seen[next] {
				seen[next] = true
				parent[next] = vertex
				depth[next] = depth[vertex] + 1
				stack[stack_size] = next
				stack_size++
			}
		}
	}
	mut a := int(qa64); mut b := int(qb64)
	if depth[a] < depth[b] { a, b = b, a }
	for depth[a] != depth[b] { a = parent[a] }
	if a == b { return i64(a) }
	for a != b { a = parent[a]; b = parent[b] }
	return i64(a)
}
