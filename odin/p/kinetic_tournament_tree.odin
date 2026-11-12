package kinetic_tournament_tree

import "core:c"

N :: 8
M :: 32
BASE :: 8
INPUT_MAX :: 2 + 2*N + 4*M
INF :: i64(1) << 60

Ktt_Node :: struct { valid: bool, winner: int, best: i64, lazy: i64, deadline: i64 }
Ktt_Op :: struct { kind, left, right, delta: i64 }

ktt_pull :: proc(tree: [^]Ktt_Node, node: int, slope: [^]i64) {
	l, r := 2*node, 2*node+1
	if !tree[l].valid && !tree[r].valid { tree[node].valid = false; tree[node].deadline = INF; return }
	if !tree[l].valid || !tree[r].valid {
		child := l; if tree[r].valid { child = r }
		tree[node].valid = true; tree[node].winner = tree[child].winner; tree[node].best = tree[child].best; tree[node].deadline = tree[child].deadline; return
	}
	li, ri := tree[l].winner, tree[r].winner
	choose_left := tree[l].best > tree[r].best || (tree[l].best == tree[r].best && slope[li] > slope[ri])
	win, lose := r, l; if choose_left { win, lose = l, r }
	wi, lo := tree[win].winner, tree[lose].winner
	crossing := INF
	if slope[wi] < slope[lo] {
		gap, sg := tree[win].best-tree[lose].best, slope[lo]-slope[wi]
		if gap <= 0 { crossing = 0 } else { crossing = (gap+sg-1)/sg }
	}
	tree[node].valid = true; tree[node].winner = wi; tree[node].best = tree[win].best
	tree[node].deadline = crossing
	if tree[l].deadline < tree[node].deadline { tree[node].deadline = tree[l].deadline }
	if tree[r].deadline < tree[node].deadline { tree[node].deadline = tree[r].deadline }
}

ktt_apply :: proc(tree: [^]Ktt_Node, node: int, slope: [^]i64, delta: i64) {
	if !tree[node].valid { return }
	tree[node].best += slope[tree[node].winner]*delta
	tree[node].lazy += delta; tree[node].deadline -= delta
}
ktt_push :: proc(tree: [^]Ktt_Node, node: int, slope: [^]i64) {
	delta := tree[node].lazy
	if delta == 0 || node >= BASE { return }
	ktt_apply(tree, 2*node, slope, delta); ktt_apply(tree, 2*node+1, slope, delta); tree[node].lazy = 0
}
ktt_repair :: proc(tree: [^]Ktt_Node, node: int, slope: [^]i64) {
	if node >= BASE || !tree[node].valid { return }
	ktt_push(tree, node, slope)
	if tree[2*node].valid && tree[2*node].deadline <= 0 { ktt_repair(tree, 2*node, slope) }
	if tree[2*node+1].valid && tree[2*node+1].deadline <= 0 { ktt_repair(tree, 2*node+1, slope) }
	ktt_pull(tree, node, slope)
}
ktt_translate :: proc(tree: [^]Ktt_Node, node, lo, hi, ql, qr: int, delta: i64, slope: [^]i64) {
	if ql <= lo && hi <= qr { ktt_apply(tree, node, slope, delta); ktt_repair(tree, node, slope); return }
	ktt_push(tree, node, slope); mid := (lo+hi)/2
	if ql < mid { ktt_translate(tree, 2*node, lo, mid, ql, qr, delta, slope) }
	if mid < qr { ktt_translate(tree, 2*node+1, mid, hi, ql, qr, delta, slope) }
	ktt_pull(tree, node, slope)
}
ktt_query :: proc(tree: [^]Ktt_Node, node, lo, hi, ql, qr: int, slope: [^]i64) -> i64 {
	if ql <= lo && hi <= qr { return tree[node].best }
	ktt_push(tree, node, slope); mid := (lo+hi)/2; answer := i64(-9223372036854775807-1)
	if ql < mid { answer = ktt_query(tree, 2*node, lo, mid, ql, qr, slope) }
	if mid < qr { other := ktt_query(tree, 2*node+1, mid, hi, ql, qr, slope); if other > answer { answer = other } }
	ktt_pull(tree, node, slope); return answer
}
ktt_store :: proc(out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { out[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
kinetic_tournament_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > INPUT_MAX do return -1
	nr, mr := input[0], input[1]
	if nr < 1 || nr > N || mr < 1 || mr > M do return -1
	n, m, cursor := int(nr), int(mr), 2
	slope, intercept: [N]i64
	for i := 0; i < n; i += 1 {
		if cursor+2 > int(length) do return -1
		slope[i], intercept[i] = input[cursor], input[cursor+1]; cursor += 2
		if slope[i] < -8 || slope[i] > 8 || intercept[i] < -64 || intercept[i] > 64 || (i > 0 && slope[i] <= slope[i-1]) do return -1
	}
	ops: [M]Ktt_Op
	query_count := 0
	for i := 0; i < m; i += 1 {
		if cursor >= int(length) do return -1
		kind := input[cursor]; cursor += 1
		if kind == 0 {
			if cursor+3 > int(length) do return -1
			left, right, delta := input[cursor], input[cursor+1], input[cursor+2]; cursor += 3
			if left < 0 || left > right || right >= nr || delta < 1 || delta > 8 do return -1
			ops[i] = {kind, left, right, delta}
		} else if kind == 1 {
			if cursor+2 > int(length) do return -1
			left, right := input[cursor], input[cursor+1]; cursor += 2
			if left < 0 || left > right || right >= nr do return -1
			ops[i] = {kind, left, right, 0}; query_count += 1
		} else { return -1 }
	}
	if cursor != int(length) || query_count == 0 do return -1
	required := 8*query_count
	if output == nil || capacity < c.size_t(required) do return -2
	tree: [2*BASE]Ktt_Node
	for i := 0; i < 2*BASE; i += 1 { tree[i].deadline = INF }
	for i := 0; i < n; i += 1 { node := BASE+i; tree[node].valid = true; tree[node].winner = i; tree[node].best = intercept[i] }
	for node := BASE-1; node > 0; node -= 1 { ktt_pull(&tree[0], node, &slope[0]) }
	answers: [M]i64
	answer_count := 0
	for i := 0; i < m; i += 1 {
		op := ops[i]
		if op.kind == 0 { ktt_translate(&tree[0], 1, 0, BASE, int(op.left), int(op.right)+1, op.delta, &slope[0]) }
		else { answers[answer_count] = ktt_query(&tree[0], 1, 0, BASE, int(op.left), int(op.right)+1, &slope[0]); answer_count += 1 }
	}
	for i := 0; i < answer_count; i += 1 { ktt_store(output, 8*i, answers[i]) }
	return i64(required)
}
