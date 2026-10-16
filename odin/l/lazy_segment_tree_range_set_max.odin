package lazy_segment_tree_range_set_max

import "core:c"

MAX_N :: 256
MAX_Q :: 512
MAX_INPUT :: 2306
CHECKSUM_OFFSET :: i64(1_000_001)

build :: proc(node, left, right: int, values, tree: [^]i64) {
	if left == right { tree[node] = values[left]; return }
	mid := left + (right - left) / 2
	build(node * 2, left, mid, values, tree)
	build(node * 2 + 1, mid + 1, right, values, tree)
	tree[node] = max(tree[node * 2], tree[node * 2 + 1])
}

push :: proc(node, left, right: int, tree, lazy: [^]i64, pending: [^]bool) {
	if !pending[node] do return
	tree[node] = lazy[node]
	pending[node] = false
	if left != right {
		child := node * 2
		lazy[child] = tree[node]; lazy[child + 1] = tree[node]
		pending[child] = true; pending[child + 1] = true
	}
}

assign_range :: proc(node, left, right, ql, qr: int, value: i64, tree, lazy: [^]i64, pending: [^]bool) {
	push(node, left, right, tree, lazy, pending)
	if right < ql || left > qr do return
	if ql <= left && right <= qr {
		tree[node] = value
		if left != right {
			child := node * 2
			lazy[child] = value; lazy[child + 1] = value
			pending[child] = true; pending[child + 1] = true
		}
		return
	}
	mid := left + (right - left) / 2
	assign_range(node * 2, left, mid, ql, qr, value, tree, lazy, pending)
	assign_range(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending)
	tree[node] = max(tree[node * 2], tree[node * 2 + 1])
}

range_max :: proc(node, left, right, ql, qr: int, tree, lazy: [^]i64, pending: [^]bool) -> i64 {
	push(node, left, right, tree, lazy, pending)
	if right < ql || left > qr do return i64(-9223372036854775807) - 1
	if ql <= left && right <= qr do return tree[node]
	mid := left + (right - left) / 2
	return max(range_max(node * 2, left, mid, ql, qr, tree, lazy, pending),
	           range_max(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending))
}

@(export)
lazy_segment_tree_range_set_max :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > MAX_INPUT do return -1
	nv, qv := packed[0], packed[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if int(length) < 2 + n do return -1
	initial: [MAX_N]i64
	for i in 0..<n {
		initial[i] = packed[2 + i]
		if initial[i] < -1_000_000 || initial[i] > 1_000_000 do return -1
	}
	offset := 2 + n
	opcodes: [MAX_Q]u8
	lefts, rights: [MAX_Q]int
	assigned: [MAX_Q]i64
	for i in 0..<q {
		if offset >= int(length) do return -1
		op := packed[offset]
		width := if op == 0 { 3 } else if op == 1 { 4 } else { 0 }
		if width == 0 || offset + width > int(length) do return -1
		l, r := packed[offset + 1], packed[offset + 2]
		if l < 0 || l >= r || r > nv do return -1
		opcodes[i] = u8(op); lefts[i] = int(l); rights[i] = int(r)
		if op == 1 {
			assigned[i] = packed[offset + 3]
			if assigned[i] < -1_000_000 || assigned[i] > 1_000_000 do return -1
		}
		offset += width
	}
	if offset != int(length) do return -1
	tree, lazy: [1024]i64
	pending: [1024]bool
	build(1, 0, n - 1, &initial[0], &tree[0])
	checksum, ordinal := i64(0), i64(0)
	for i in 0..<q {
		if opcodes[i] == 1 do assign_range(1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i], &tree[0], &lazy[0], &pending[0])
		else {
			answer := range_max(1, 0, n - 1, lefts[i], rights[i] - 1, &tree[0], &lazy[0], &pending[0])
			ordinal += 1
			checksum += ordinal * (answer + CHECKSUM_OFFSET)
		}
	}
	return checksum
}
