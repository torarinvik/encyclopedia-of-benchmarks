module lazy_segment_tree_range_set_max

const max_n = 256
const max_q = 512
const max_input = 2306
const checksum_offset = i64(1000001)

fn build(mut tree []i64, values []i64, node int, left int, right int) {
	if left == right { tree[node] = values[left]; return }
	mid := left + (right - left) / 2
	build(mut tree, values, node * 2, left, mid)
	build(mut tree, values, node * 2 + 1, mid + 1, right)
	tree[node] = if tree[node * 2] > tree[node * 2 + 1] { tree[node * 2] } else { tree[node * 2 + 1] }
}

fn push(mut tree []i64, mut lazy []i64, mut pending []bool, node int, left int, right int) {
	if !pending[node] { return }
	tree[node] = lazy[node]
	pending[node] = false
	if left != right {
		child := node * 2
		lazy[child] = tree[node]
		lazy[child + 1] = tree[node]
		pending[child] = true
		pending[child + 1] = true
	}
}

fn assign_range(mut tree []i64, mut lazy []i64, mut pending []bool, node int, left int, right int, ql int, qr int, value i64) {
	push(mut tree, mut lazy, mut pending, node, left, right)
	if right < ql || left > qr { return }
	if ql <= left && right <= qr {
		tree[node] = value
		if left != right {
			child := node * 2
			lazy[child] = value
			lazy[child + 1] = value
			pending[child] = true
			pending[child + 1] = true
		}
		return
	}
	mid := left + (right - left) / 2
	assign_range(mut tree, mut lazy, mut pending, node * 2, left, mid, ql, qr, value)
	assign_range(mut tree, mut lazy, mut pending, node * 2 + 1, mid + 1, right, ql, qr, value)
	tree[node] = if tree[node * 2] > tree[node * 2 + 1] { tree[node * 2] } else { tree[node * 2 + 1] }
}

fn range_max(mut tree []i64, mut lazy []i64, mut pending []bool, node int, left int, right int, ql int, qr int) i64 {
	push(mut tree, mut lazy, mut pending, node, left, right)
	if right < ql || left > qr { return i64(-9223372036854775807) - 1 }
	if ql <= left && right <= qr { return tree[node] }
	mid := left + (right - left) / 2
	a := range_max(mut tree, mut lazy, mut pending, node * 2, left, mid, ql, qr)
	b := range_max(mut tree, mut lazy, mut pending, node * 2 + 1, mid + 1, right, ql, qr)
	return if a > b { a } else { b }
}

@[export: 'lazy_segment_tree_range_set_max']
pub fn lazy_segment_tree_range_set_max(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 2 || length > max_input { return -1 }
	nv := unsafe { packed[0] }
	qv := unsafe { packed[1] }
	if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv)
	q := int(qv)
	if int(length) < 2 + n { return -1 }
	mut values := []i64{len: n}
	for i in 0 .. n {
		values[i] = unsafe { packed[2 + i] }
		if values[i] < -1000000 || values[i] > 1000000 { return -1 }
	}
	mut offset := 2 + n
	mut opcodes := []int{len: q}
	mut lefts := []int{len: q}
	mut rights := []int{len: q}
	mut assigned := []i64{len: q}
	for i in 0 .. q {
		if offset >= int(length) { return -1 }
		op := unsafe { packed[offset] }
		width := if op == 0 { 3 } else if op == 1 { 4 } else { 0 }
		if width == 0 || offset + width > int(length) { return -1 }
		l := unsafe { packed[offset + 1] }
		r := unsafe { packed[offset + 2] }
		if l < 0 || l >= r || r > nv { return -1 }
		opcodes[i] = int(op)
		lefts[i] = int(l)
		rights[i] = int(r)
		if op == 1 {
			assigned[i] = unsafe { packed[offset + 3] }
			if assigned[i] < -1000000 || assigned[i] > 1000000 { return -1 }
		}
		offset += width
	}
	if offset != int(length) { return -1 }
	mut tree := []i64{len: 1024}
	mut lazy := []i64{len: 1024}
	mut pending := []bool{len: 1024}
	build(mut tree, values, 1, 0, n - 1)
	mut checksum := i64(0)
	mut ordinal := i64(0)
	for i in 0 .. q {
		if opcodes[i] == 1 { assign_range(mut tree, mut lazy, mut pending, 1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i]) }
		else {
			answer := range_max(mut tree, mut lazy, mut pending, 1, 0, n - 1, lefts[i], rights[i] - 1)
			ordinal++
			checksum += ordinal * (answer + checksum_offset)
		}
	}
	return checksum
}
