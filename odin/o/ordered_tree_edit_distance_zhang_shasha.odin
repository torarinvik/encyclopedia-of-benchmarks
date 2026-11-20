package ordered_tree_edit_distance_zhang_shasha

import "core:c"

MAX_N :: 8
MAX_LEN :: 35
INF :: i64(1000000)

Tree :: struct {
	n: int,
	labels: [MAX_N]i64,
	children: [MAX_N][MAX_N]int,
	child_count: [MAX_N]int,
}
Post :: struct {
	n: int,
	labels: [MAX_N + 1]i64,
	leftmost: [MAX_N + 1]int,
}

post_visit :: proc(tree: ^Tree, vertex: int, post: ^Post) -> int {
	left := 0
	for k := 0; k < tree.child_count[vertex]; k += 1 {
		child_left := post_visit(tree, tree.children[vertex][k], post)
		if k == 0 do left = child_left
	}
	post.n += 1
	id := post.n
	post.labels[id] = tree.labels[vertex]
	post.leftmost[id] = left if left != 0 else id
	return post.leftmost[id]
}

read_tree :: proc(values: [^]i64, position: ^int, n: int) -> (Tree, bool) {
	tree: Tree
	tree.n = n
	for v := 0; v < n; v += 1 {
		label := values[position^]
		position^ += 1
		if label < 0 || label > 3 do return tree, false
		tree.labels[v] = label
	}
	stack: [MAX_N]int
	top := 0
	for v := 0; v < n; v += 1 {
		parent := values[position^]
		position^ += 1
		if v == 0 {
			if parent != -1 do return tree, false
			stack[0] = 0
			continue
		}
		if parent < 0 || parent >= i64(v) do return tree, false
		for top >= 0 && stack[top] != int(parent) { top -= 1 }
		if top < 0 do return tree, false
		p := int(parent)
		tree.children[p][tree.child_count[p]] = v
		tree.child_count[p] += 1
		top += 1
		stack[top] = v
	}
	return tree, true
}

distance :: proc(a, b: ^Tree) -> i64 {
	pa: Post
	pb: Post
	_ = post_visit(a, 0, &pa)
	_ = post_visit(b, 0, &pb)
	key_a: [MAX_N + 1]int
	key_b: [MAX_N + 1]int
	for i := 1; i <= pa.n; i += 1 { key_a[pa.leftmost[i]] = i }
	for j := 1; j <= pb.n; j += 1 { key_b[pb.leftmost[j]] = j }
	td: [MAX_N + 1][MAX_N + 1]i64
	for ra := 1; ra <= pa.n; ra += 1 {
		if key_a[pa.leftmost[ra]] != ra do continue
		for rb := 1; rb <= pb.n; rb += 1 {
			if key_b[pb.leftmost[rb]] != rb do continue
			sa := pa.leftmost[ra]
			sb := pb.leftmost[rb]
			fd: [MAX_N + 1][MAX_N + 1]i64
			for x := 0; x <= MAX_N; x += 1 {
				for y := 0; y <= MAX_N; y += 1 { fd[x][y] = INF }
			}
			fd[sa-1][sb-1] = 0
			for x := sa; x <= ra; x += 1 { fd[x][sb-1] = fd[x-1][sb-1] + 1 }
			for y := sb; y <= rb; y += 1 { fd[sa-1][y] = fd[sa-1][y-1] + 1 }
			for x := sa; x <= ra; x += 1 {
				for y := sb; y <= rb; y += 1 {
					del := fd[x-1][y] + 1
					ins := fd[x][y-1] + 1
					if pa.leftmost[x] == sa && pb.leftmost[y] == sb {
						rename := fd[x-1][y-1]
						if pa.labels[x] != pb.labels[y] { rename += 1 }
                        best := min(min(del, ins), rename)
						fd[x][y] = best
						td[x][y] = best
					} else {
						join := fd[pa.leftmost[x]-1][pb.leftmost[y]-1] + td[x][y]
                        fd[x][y] = min(min(del, ins), join)
					}
				}
			}
		}
	}
	return td[pa.n][pb.n]
}

solve :: proc(values: [^]i64, length: c.size_t) -> i64 {
	if length < 6 || length > MAX_LEN do return -1
	n1v, n2v := values[0], values[1]
	if n1v < 1 || n1v > i64(MAX_N) || n2v < 1 || n2v > i64(MAX_N) do return -1
	n1, n2 := int(n1v), int(n2v)
	if length != c.size_t(2 + 2*n1 + 2*n2) do return -1
	position := 2
	a, ok_a := read_tree(values, &position, n1)
	if !ok_a do return -1
	b, ok_b := read_tree(values, &position, n2)
	if !ok_b do return -1
	return distance(&a, &b)
}

@(export)
ordered_tree_edit_distance_zhang_shasha :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_LEN do return -1
	return solve(input, length)
}
