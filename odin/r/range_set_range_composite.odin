package range_set_range_composite

import "core:c"

Modulus :: i64(998244353)
Max_N :: 64
Max_Q :: 32
Max_Input :: 291
Tree_N :: 4 * Max_N + 5

Affine :: struct { a, b: i64 }
Node :: struct { value: Affine, lazy_a, lazy_b: i64, has_lazy: bool }
Operation :: struct { kind, left, right: int, x, y: i64 }

identity :: proc() -> Affine { return {1, 0} }
compose :: proc(after, before: Affine) -> Affine {
	return {(after.a * before.a) % Modulus, (after.a * before.b + after.b) % Modulus}
}
power_map :: proc(a, b: i64, count: int) -> Affine {
	result := identity(); base := Affine{a, b}; exponent := count
	for exponent > 0 {
		if exponent & 1 == 1 { result = compose(base, result) }
		base = compose(base, base); exponent >>= 1
	}
	return result
}
build :: proc(tree: ^[Tree_N]Node, node, left, right: int, a, b: ^[Max_N]i64) {
	if right - left == 1 { tree[node].value = {a[left], b[left]}; return }
	mid := left + (right - left) / 2
	build(tree, node * 2, left, mid, a, b); build(tree, node * 2 + 1, mid, right, a, b)
	tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)
}
apply :: proc(tree: ^[Tree_N]Node, node, left, right: int, a, b: i64) {
	tree[node].value = power_map(a, b, right - left); tree[node].lazy_a = a; tree[node].lazy_b = b; tree[node].has_lazy = true
}
push :: proc(tree: ^[Tree_N]Node, node, left, right: int) {
	if !tree[node].has_lazy || right - left == 1 { return }
	mid := left + (right - left) / 2; a, b := tree[node].lazy_a, tree[node].lazy_b
	apply(tree, node * 2, left, mid, a, b); apply(tree, node * 2 + 1, mid, right, a, b); tree[node].has_lazy = false
}
update :: proc(tree: ^[Tree_N]Node, node, left, right, ql, qr: int, a, b: i64) {
	if ql <= left && right <= qr { apply(tree, node, left, right, a, b); return }
	push(tree, node, left, right); mid := left + (right - left) / 2
	if ql < mid { update(tree, node * 2, left, mid, ql, qr, a, b) }
	if qr > mid { update(tree, node * 2 + 1, mid, right, ql, qr, a, b) }
	tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value)
}
query :: proc(tree: ^[Tree_N]Node, node, left, right, ql, qr: int) -> Affine {
	if ql <= left && right <= qr { return tree[node].value }
	push(tree, node, left, right); mid := left + (right - left) / 2
	if qr <= mid { return query(tree, node * 2, left, mid, ql, qr) }
	if ql >= mid { return query(tree, node * 2 + 1, mid, right, ql, qr) }
	return compose(query(tree, node * 2 + 1, mid, right, ql, qr), query(tree, node * 2, left, mid, ql, qr))
}
put64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for j := 0; j < 8; j += 1 { output[offset + j] = u8((bits >> (8 * j)) & 255) }
}

@(export)
range_set_range_composite :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > i64(Max_N) || qv < 1 || qv > i64(Max_Q) do return -1
	n, q := int(nv), int(qv)
	init_a: [Max_N]i64; init_b: [Max_N]i64
	offset := 2
	if int(length) < offset + 2*n do return -1
	for i := 0; i < n; i += 1 {
		a, b := input[offset], input[offset + 1]; offset += 2
		if a < 1 || a >= Modulus || b < 0 || b >= Modulus do return -1
		init_a[i], init_b[i] = a, b
	}
	ops: [Max_Q]Operation; answer_count := 0
	for k := 0; k < q; k += 1 {
		if offset >= int(length) do return -1
		kind := input[offset]; offset += 1
		if kind == 0 {
			if offset + 4 > int(length) do return -1
			l, r, a, b := input[offset], input[offset+1], input[offset+2], input[offset+3]; offset += 4
			if l < 0 || l >= r || r > nv || a < 1 || a >= Modulus || b < 0 || b >= Modulus do return -1
			ops[k] = {0, int(l), int(r), a, b}
		} else if kind == 1 {
			if offset + 3 > int(length) do return -1
			l, r, x := input[offset], input[offset+1], input[offset+2]; offset += 3
			if l < 0 || l >= r || r > nv || x < 0 || x >= Modulus do return -1
			ops[k] = {1, int(l), int(r), x, 0}; answer_count += 1
		} else { return -1 }
	}
	if offset != int(length) do return -1
	tree: [Tree_N]Node
	build(&tree, 1, 0, n, &init_a, &init_b)
	answers: [Max_Q]i64; answer_index := 0
	for k := 0; k < q; k += 1 {
		op := ops[k]
		if op.kind == 0 { update(&tree, 1, 0, n, op.left, op.right, op.x, op.y) }
		else { z := query(&tree, 1, 0, n, op.left, op.right); answers[answer_index] = (z.a*op.x + z.b) % Modulus; answer_index += 1 }
	}
	bytes := c.size_t(8 * answer_count)
	if output == nil || capacity < bytes do return -2
	for i := 0; i < answer_count; i += 1 { put64(output, 8*i, answers[i]) }
	return i64(bytes)
}
