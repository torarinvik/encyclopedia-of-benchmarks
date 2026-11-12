module dynamic_point_set_rectangle_affine_rectangle_sum

const max_n = 32
const max_q = 32
const max_points = max_n + max_q
const max_tree = 4 * max_points + 8
const max_input = 2 + 3 * max_n + 7 * max_q + 1
const modulus i64 = 998244353
const max_coord i64 = 1000000000

struct Op { kind i64; a i64; b i64; c i64; d i64; e i64; f i64 }
struct Node { min_x i64; max_x i64; min_y i64; max_y i64; sum i64; lazy_a i64; lazy_b i64; active int }

fn less_point(a int, b int, axis int, xs []i64, ys []i64) bool {
	av := if axis == 0 { xs[a] } else { ys[a] }
	bv := if axis == 0 { xs[b] } else { ys[b] }
	if av != bv { return av < bv }
	ao := if axis == 0 { ys[a] } else { xs[a] }
	bo := if axis == 0 { ys[b] } else { xs[b] }
	if ao != bo { return ao < bo }
	return a < b
}
fn sort_points(mut order []int, low int, high int, axis int, xs []i64, ys []i64) {
	for i := low + 1; i < high; i++ {
		point := order[i]
		mut j := i
		for j > low && less_point(point, order[j - 1], axis, xs, ys) { order[j] = order[j - 1]; j-- }
		order[j] = point
	}
}
fn build(mut tree []Node, mut order []int, mut rank []int, xs []i64, ys []i64,
	weights []i64, low int, high int, index int, depth int, initial_n int) {
	tree[index].lazy_a = 1
	if high - low == 1 {
		p := order[low]
		tree[index].min_x = xs[p]; tree[index].max_x = xs[p]
		tree[index].min_y = ys[p]; tree[index].max_y = ys[p]
		tree[index].active = if p < initial_n { 1 } else { 0 }
		tree[index].sum = if p < initial_n { weights[p] } else { 0 }
		rank[p] = low
		return
	}
	sort_points(mut order, low, high, depth & 1, xs, ys)
	mid := low + (high - low) / 2
	build(mut tree, mut order, mut rank, xs, ys, weights, low, mid, index * 2, depth + 1, initial_n)
	build(mut tree, mut order, mut rank, xs, ys, weights, mid, high, index * 2 + 1, depth + 1, initial_n)
	l := tree[index * 2]; r := tree[index * 2 + 1]
	tree[index].min_x = min(l.min_x, r.min_x); tree[index].max_x = max(l.max_x, r.max_x)
	tree[index].min_y = min(l.min_y, r.min_y); tree[index].max_y = max(l.max_y, r.max_y)
	tree[index].active = l.active + r.active; tree[index].sum = (l.sum + r.sum) % modulus
}
fn apply(mut tree []Node, i int, a i64, b i64) {
	if tree[i].active == 0 { return }
	tree[i].sum = (a * tree[i].sum + b * i64(tree[i].active)) % modulus
	tree[i].lazy_a = a * tree[i].lazy_a % modulus
	tree[i].lazy_b = (a * tree[i].lazy_b + b) % modulus
}
fn push(mut tree []Node, i int, low int, high int) {
	if high - low == 1 || (tree[i].lazy_a == 1 && tree[i].lazy_b == 0) { return }
	a := tree[i].lazy_a; b := tree[i].lazy_b
	apply(mut tree, i * 2, a, b); apply(mut tree, i * 2 + 1, a, b)
	tree[i].lazy_a = 1; tree[i].lazy_b = 0
}
fn disjoint(n Node, l i64, d i64, r i64, u i64) bool { return n.max_x < l || n.min_x >= r || n.max_y < d || n.min_y >= u }
fn covered(n Node, l i64, d i64, r i64, u i64) bool { return l <= n.min_x && n.max_x < r && d <= n.min_y && n.max_y < u }
fn pull(mut tree []Node, i int) {
	tree[i].sum = (tree[i * 2].sum + tree[i * 2 + 1].sum) % modulus
	tree[i].active = tree[i * 2].active + tree[i * 2 + 1].active
}
fn rect_sum(mut tree []Node, i int, low int, high int, l i64, d i64, r i64, u i64) i64 {
	n := tree[i]
	if n.active == 0 || disjoint(n, l, d, r, u) { return 0 }
	if covered(n, l, d, r, u) { return n.sum }
	push(mut tree, i, low, high)
	mid := low + (high - low) / 2
	return (rect_sum(mut tree, i * 2, low, mid, l, d, r, u) + rect_sum(mut tree, i * 2 + 1, mid, high, l, d, r, u)) % modulus
}
fn rect_affine(mut tree []Node, i int, low int, high int, l i64, d i64, r i64, u i64, a i64, b i64) {
	n := tree[i]
	if n.active == 0 || disjoint(n, l, d, r, u) { return }
	if covered(n, l, d, r, u) { apply(mut tree, i, a, b); return }
	push(mut tree, i, low, high)
	mid := low + (high - low) / 2
	rect_affine(mut tree, i * 2, low, mid, l, d, r, u, a, b)
	rect_affine(mut tree, i * 2 + 1, mid, high, l, d, r, u, a, b)
	pull(mut tree, i)
}
fn set_point(mut tree []Node, i int, low int, high int, target int, weight i64) {
	if high - low == 1 { tree[i].sum = weight; tree[i].active = 1; tree[i].lazy_a = 1; tree[i].lazy_b = 0; return }
	push(mut tree, i, low, high)
	mid := low + (high - low) / 2
	if target < mid { set_point(mut tree, i * 2, low, mid, target, weight) } else { set_point(mut tree, i * 2 + 1, mid, high, target, weight) }
	pull(mut tree, i)
}
fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for b in 0 .. 8 { output[offset + b] = u8((bits >> (8 * b)) & 255) } }
}

@[export: 'dynamic_point_set_rectangle_affine_rectangle_sum']
pub fn dynamic_point_set_rectangle_affine_rectangle_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input) { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
	n := int(nv); q := int(qv)
	if 2 + 3 * n > int(length) { return -1 }
	mut xs := []i64{len: max_points}; mut ys := []i64{len: max_points}; mut weights := []i64{len: max_points}
	mut ops := []Op{len: max_q}; mut points := n; mut active := n; mut query_count := 0
	for i in 0 .. n {
		xs[i] = unsafe { input[2 + 3 * i] }; ys[i] = unsafe { input[3 + 3 * i] }; weights[i] = unsafe { input[4 + 3 * i] }
		if xs[i] < 0 || xs[i] > max_coord || ys[i] < 0 || ys[i] > max_coord || weights[i] < 0 || weights[i] >= modulus { return -1 }
	}
	mut cursor := 2 + 3 * n
	for oi in 0 .. q {
		if cursor >= int(length) { return -1 }
		kind := unsafe { input[cursor] }; cursor++
		if kind == 0 {
			if cursor + 3 > int(length) || points >= max_points { return -1 }
			x := unsafe { input[cursor] }; y := unsafe { input[cursor + 1] }; w := unsafe { input[cursor + 2] }; cursor += 3
			if x < 0 || x > max_coord || y < 0 || y > max_coord || w < 0 || w >= modulus { return -1 }
			xs[points] = x; ys[points] = y; ops[oi] = Op{kind: kind, a: i64(points), b: w, c: 0, d: 0, e: 0, f: 0}; points++; active++
		} else if kind == 1 {
			if cursor + 2 > int(length) { return -1 }
			id := unsafe { input[cursor] }; w := unsafe { input[cursor + 1] }; cursor += 2
			if id < 0 || id >= i64(active) || w < 0 || w >= modulus { return -1 }
			ops[oi] = Op{kind: kind, a: id, b: w, c: 0, d: 0, e: 0, f: 0}
		} else if kind == 2 || kind == 3 {
			fields := if kind == 2 { 4 } else { 6 }; if cursor + fields > int(length) { return -1 }
			l := unsafe { input[cursor] }; d := unsafe { input[cursor + 1] }; r := unsafe { input[cursor + 2] }; u := unsafe { input[cursor + 3] }
			if l < 0 || l >= r || r > max_coord || d < 0 || d >= u || u > max_coord { return -1 }
			if kind == 2 { cursor += 4; ops[oi] = Op{kind: kind, a: l, b: d, c: r, d: u, e: 0, f: 0}; query_count++ } else { a := unsafe { input[cursor + 4] }; b := unsafe { input[cursor + 5] }; cursor += 6; if a < 0 || a >= modulus || b < 0 || b >= modulus { return -1 }; ops[oi] = Op{kind: kind, a: l, b: d, c: r, d: u, e: a, f: b} }
		} else { return -1 }
	}
	if cursor != int(length) { return -1 }
	output_bytes := 8 * query_count
	if output_bytes > 0 && (unsafe { output == nil } || capacity < usize(output_bytes)) { return -2 }
	mut tree := []Node{len: max_tree}; mut order := []int{len: max_points}; mut rank := []int{len: max_points}
	for i in 0 .. points { order[i] = i }
	build(mut tree, mut order, mut rank, xs, ys, weights, 0, points, 1, 0, n)
	mut answers := []i64{len: max_q}; mut answer_count := 0
	for oi in 0 .. q {
		op := ops[oi]
		if op.kind == 0 || op.kind == 1 { set_point(mut tree, 1, 0, points, rank[int(op.a)], op.b) }
		else if op.kind == 2 { answers[answer_count] = rect_sum(mut tree, 1, 0, points, op.a, op.b, op.c, op.d); answer_count++ } else { rect_affine(mut tree, 1, 0, points, op.a, op.b, op.c, op.d, op.e, op.f) }
	}
	for i in 0 .. answer_count { store_le(mut output, i * 8, answers[i]) }
	return i64(output_bytes)
}
