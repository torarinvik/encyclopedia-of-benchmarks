module ordered_tree_edit_distance_zhang_shasha

const max_n = 8
const max_len = 35
const inf = i64(1000000)

struct Tree {
	n int
	labels [8]i64
	children [8][8]int
	child_count [8]int
}

struct Post {
	n int
	labels [9]i64
	leftmost [9]int
}

fn post_visit(tree &Tree, vertex int, mut post Post) int {
	mut left := 0
	for k in 0 .. tree.child_count[vertex] {
		child_left := post_visit(tree, tree.children[vertex][k], mut post)
		if k == 0 { left = child_left }
	}
	post.n++
	id := post.n
	post.labels[id] = tree.labels[vertex]
	post.leftmost[id] = if left == 0 { id } else { left }
	return post.leftmost[id]
}

fn read_tree(values []i64, mut position int, n int) ?Tree {
	mut tree := Tree{n: n}
	for v in 0 .. n {
		label := values[position]
		position++
		if label < 0 || label > 3 { return none }
		tree.labels[v] = label
	}
	mut stack := [8]int{}
	mut top := 0
	for v in 0 .. n {
		parent := values[position]
		position++
		if v == 0 {
			if parent != -1 { return none }
			stack[0] = 0
			continue
		}
		if parent < 0 || parent >= i64(v) { return none }
		for top >= 0 && stack[top] != int(parent) { top-- }
		if top < 0 { return none }
		p := int(parent)
		tree.children[p][tree.child_count[p]] = v
		tree.child_count[p]++
		top++
		stack[top] = v
	}
	return tree
}

fn distance(a &Tree, b &Tree) i64 {
	mut pa := Post{}
	mut pb := Post{}
	_ = post_visit(a, 0, mut pa)
	_ = post_visit(b, 0, mut pb)
	mut key_a := [9]int{}
	mut key_b := [9]int{}
	for i in 1 .. pa.n + 1 { key_a[pa.leftmost[i]] = i }
	for j in 1 .. pb.n + 1 { key_b[pb.leftmost[j]] = j }
	mut td := [9][9]i64{}
	for ra in 1 .. pa.n + 1 {
		if key_a[pa.leftmost[ra]] != ra { continue }
		for rb in 1 .. pb.n + 1 {
			if key_b[pb.leftmost[rb]] != rb { continue }
			sa := pa.leftmost[ra]
			sb := pb.leftmost[rb]
			mut fd := [9][9]i64{}
			for x in 0 .. 9 { for y in 0 .. 9 { fd[x][y] = inf } }
			fd[sa - 1][sb - 1] = 0
			for x in sa .. ra + 1 { fd[x][sb - 1] = fd[x - 1][sb - 1] + 1 }
			for y in sb .. rb + 1 { fd[sa - 1][y] = fd[sa - 1][y - 1] + 1 }
			for x in sa .. ra + 1 {
				for y in sb .. rb + 1 {
					del := fd[x - 1][y] + 1
					ins := fd[x][y - 1] + 1
					if pa.leftmost[x] == sa && pb.leftmost[y] == sb {
						rename := fd[x - 1][y - 1]
						if pa.labels[x] != pb.labels[y] { rename++ }
						best := min(del, min(ins, rename))
						fd[x][y] = best
						td[x][y] = best
					} else {
						join := fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y]
						fd[x][y] = min(del, min(ins, join))
					}
				}
			}
		}
	}
	return td[pa.n][pb.n]
}

fn solve(values []i64) i64 {
	length := values.len
	if length < 6 || length > max_len { return -1 }
	n1v, n2v := values[0], values[1]
	if n1v < 1 || n1v > max_n || n2v < 1 || n2v > max_n { return -1 }
	n1, n2 := int(n1v), int(n2v)
	if length != usize(2 + 2 * n1 + 2 * n2) { return -1 }
	mut position := 2
	a := read_tree(values, mut position, n1) or { return -1 }
	b := read_tree(values, mut position, n2) or { return -1 }
	return distance(a, b)
}

@[export: 'ordered_tree_edit_distance_zhang_shasha']
pub fn ordered_tree_edit_distance_zhang_shasha(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > usize(max_len) { return -1 }
		mut values := [35]i64{}
		for i in 0 .. int(length) { values[i] = input[i] }
		return solve(values[..int(length)])
	}
}
