module range_set_range_composite

const modulus = i64(998244353)
const max_n = 64
const max_q = 32
const max_input_length = 291
const tree_size = 4 * max_n + 5

struct Affine { a i64 = 1; b i64 = 0 }
struct Node { value Affine; lazy_a i64 = 1; lazy_b i64; has_lazy bool }
struct Operation { kind int; left int; right int; x i64; y i64 }

fn compose(after Affine, before Affine) Affine {
	return Affine{a: (after.a * before.a) % modulus, b: (after.a * before.b + after.b) % modulus}
}
fn power_map(a i64, b i64, count int) Affine {
	mut result := Affine{}
	mut base := Affine{a: a, b: b}
	mut exponent := count
	for exponent > 0 {
		if exponent & 1 == 1 { result = compose(base, result) }
		base = compose(base, base)
		exponent >>= 1
	}
	return result
}
fn build(mut tree [tree_size]Node, left int, right int, a [max_n]i64, b [max_n]i64, node int) {
	if right - left == 1 { tree[node].value = Affine{a: a[left], b: b[left]}; return }
	mid := left + (right - left) / 2
	build(mut tree, left, mid, a, b, node * 2)
	build(mut tree, mid, right, a, b, node * 2 + 1)
	tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)
}
fn apply(mut tree [tree_size]Node, node int, left int, right int, a i64, b i64) {
	tree[node].value = power_map(a, b, right - left)
	tree[node].lazy_a = a; tree[node].lazy_b = b; tree[node].has_lazy = true
}
fn push(mut tree [tree_size]Node, node int, left int, right int) {
	if !tree[node].has_lazy || right - left == 1 { return }
	mid := left + (right - left) / 2
	a := tree[node].lazy_a; b := tree[node].lazy_b
	apply(mut tree, node * 2, left, mid, a, b); apply(mut tree, node * 2 + 1, mid, right, a, b)
	tree[node].has_lazy = false
}
fn update(mut tree [tree_size]Node, node int, left int, right int, ql int, qr int, a i64, b i64) {
	if ql <= left && right <= qr { apply(mut tree, node, left, right, a, b); return }
	push(mut tree, node, left, right); mid := left + (right - left) / 2
	if ql < mid { update(mut tree, node * 2, left, mid, ql, qr, a, b) }
	if qr > mid { update(mut tree, node * 2 + 1, mid, right, ql, qr, a, b) }
	tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)
}
fn query(mut tree [tree_size]Node, node int, left int, right int, ql int, qr int) Affine {
	if ql <= left && right <= qr { return tree[node].value }
	push(mut tree, node, left, right); mid := left + (right - left) / 2
	if qr <= mid { return query(mut tree, node * 2, left, mid, ql, qr) }
	if ql >= mid { return query(mut tree, node * 2 + 1, mid, right, ql, qr) }
	return compose(query(mut tree, node * 2 + 1, mid, right, ql, qr), query(mut tree, node * 2, left, mid, ql, qr))
}
fn put64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for j in 0 .. 8 { unsafe { output[offset + j] = u8((bits >> (8 * j)) & 255) } }
}

@[export: 'range_set_range_composite']
pub fn range_set_range_composite(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
	n := int(nv); q := int(qv)
	mut init_a := [max_n]i64{}; mut init_b := [max_n]i64{}
	mut offset := 2
	if int(length) < offset + 2 * n { return -1 }
	for i in 0 .. n {
		a := unsafe { input[offset] }; b := unsafe { input[offset + 1] }; offset += 2
		if a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
		init_a[i] = a; init_b[i] = b
	}
	mut ops := [max_q]Operation{}; mut answer_count := 0
	for k in 0 .. q {
		if offset >= int(length) { return -1 }
		kind := unsafe { input[offset] }; offset++
		if kind == 0 {
			if offset + 4 > int(length) { return -1 }
			l := unsafe { input[offset] }; r := unsafe { input[offset + 1] }; a := unsafe { input[offset + 2] }; b := unsafe { input[offset + 3] }; offset += 4
			if l < 0 || l >= r || r > nv || a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			ops[k] = Operation{kind: 0, left: int(l), right: int(r), x: a, y: b}
		} else if kind == 1 {
			if offset + 3 > int(length) { return -1 }
			l := unsafe { input[offset] }; r := unsafe { input[offset + 1] }; x := unsafe { input[offset + 2] }; offset += 3
			if l < 0 || l >= r || r > nv || x < 0 || x >= modulus { return -1 }
			ops[k] = Operation{kind: 1, left: int(l), right: int(r), x: x}; answer_count++
		} else { return -1 }
	}
	if offset != int(length) { return -1 }
	mut tree := [tree_size]Node{}
	build(mut tree, 0, n, init_a, init_b, 1)
	mut answers := [max_q]i64{}; mut ai := 0
	for k in 0 .. q {
		op := ops[k]
		if op.kind == 0 { update(mut tree, 1, 0, n, op.left, op.right, op.x, op.y) }
		else { z := query(mut tree, 1, 0, n, op.left, op.right); answers[ai] = (z.a * op.x + z.b) % modulus; ai++ }
	}
	bytes := usize(8 * answer_count)
	if unsafe { output == nil } || capacity < bytes { return -2 }
	for i in 0 .. answer_count { put64(mut output, 8 * i, answers[i]) }
	return i64(bytes)
}
