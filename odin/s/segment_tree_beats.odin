package segment_tree_beats

import "core:c"

Max_Items :: 64
Max_Operations :: 128
Max_Input_Values :: 2 + Max_Items + 4 * Max_Operations
Tree_Size :: 4 * Max_Items
Value_Limit :: i64(1_000_000)
Inf :: i64(2_305_843_009_213_693_951)
Query_Offset :: i64(8_256_000_001)

Node :: struct {
	sum, max1, max2, min1, min2, add: i64,
	max_count, min_count: int,
}

pull :: proc "contextless" (tree: [^]Node, node: int) {
	left, right := tree[node * 2], tree[node * 2 + 1]
	tree[node].sum = left.sum + right.sum
	tree[node].add = 0
	if left.max1 == right.max1 {
		tree[node].max1 = left.max1
		tree[node].max2 = max(left.max2, right.max2)
		tree[node].max_count = left.max_count + right.max_count
	} else if left.max1 > right.max1 {
		tree[node].max1 = left.max1
		tree[node].max2 = max(left.max2, right.max1)
		tree[node].max_count = left.max_count
	} else {
		tree[node].max1 = right.max1
		tree[node].max2 = max(left.max1, right.max2)
		tree[node].max_count = right.max_count
	}
	if left.min1 == right.min1 {
		tree[node].min1 = left.min1
		tree[node].min2 = min(left.min2, right.min2)
		tree[node].min_count = left.min_count + right.min_count
	} else if left.min1 < right.min1 {
		tree[node].min1 = left.min1
		tree[node].min2 = min(left.min2, right.min1)
		tree[node].min_count = left.min_count
	} else {
		tree[node].min1 = right.min1
		tree[node].min2 = min(left.min1, right.min2)
		tree[node].min_count = right.min_count
	}
}

build :: proc "contextless" (tree: [^]Node, values: [^]i64, node, low, high: int) {
	if high - low == 1 {
		value := values[low]
		tree[node] = Node{value, value, -Inf, value, Inf, 0, 1, 1}
		return
	}
	middle := low + (high - low) / 2
	build(tree, values, node * 2, low, middle)
	build(tree, values, node * 2 + 1, middle, high)
	pull(tree, node)
}

apply_add :: proc "contextless" (item: ^Node, length: int, delta: i64) {
	item.sum += delta * i64(length)
	item.max1 += delta
	item.min1 += delta
	if item.max2 != -Inf do item.max2 += delta
	if item.min2 != Inf do item.min2 += delta
	item.add += delta
}

apply_chmin :: proc "contextless" (item: ^Node, ceiling: i64) {
	if item.max1 <= ceiling do return
	item.sum += (ceiling - item.max1) * i64(item.max_count)
	if item.min1 == item.max1 do item.min1 = ceiling
	else if item.min2 == item.max1 do item.min2 = ceiling
	item.max1 = ceiling
}

apply_chmax :: proc "contextless" (item: ^Node, floor: i64) {
	if item.min1 >= floor do return
	item.sum += (floor - item.min1) * i64(item.min_count)
	if item.max1 == item.min1 do item.max1 = floor
	else if item.max2 == item.min1 do item.max2 = floor
	item.min1 = floor
}

push :: proc "contextless" (tree: [^]Node, node, low, high: int) {
	if high - low == 1 do return
	middle := low + (high - low) / 2
	delta := tree[node].add
	if delta != 0 {
		apply_add(&tree[node * 2], middle - low, delta)
		apply_add(&tree[node * 2 + 1], high - middle, delta)
		tree[node].add = 0
	}
	max1 := tree[node].max1
	if tree[node * 2].max1 > max1 do apply_chmin(&tree[node * 2], max1)
	if tree[node * 2 + 1].max1 > max1 do apply_chmin(&tree[node * 2 + 1], max1)
	min1 := tree[node].min1
	if tree[node * 2].min1 < min1 do apply_chmax(&tree[node * 2], min1)
	if tree[node * 2 + 1].min1 < min1 do apply_chmax(&tree[node * 2 + 1], min1)
}

range_add :: proc "contextless" (tree: [^]Node, node, low, high, ql, qr: int, delta: i64) {
	if qr <= low || high <= ql || delta == 0 do return
	if ql <= low && high <= qr {
		apply_add(&tree[node], high - low, delta)
		return
	}
	push(tree, node, low, high)
	middle := low + (high - low) / 2
	range_add(tree, node * 2, low, middle, ql, qr, delta)
	range_add(tree, node * 2 + 1, middle, high, ql, qr, delta)
	pull(tree, node)
}

range_chmin :: proc "contextless" (tree: [^]Node, node, low, high, ql, qr: int, ceiling: i64) {
	if qr <= low || high <= ql || tree[node].max1 <= ceiling do return
	if ql <= low && high <= qr && tree[node].max2 < ceiling {
		apply_chmin(&tree[node], ceiling)
		return
	}
	push(tree, node, low, high)
	middle := low + (high - low) / 2
	range_chmin(tree, node * 2, low, middle, ql, qr, ceiling)
	range_chmin(tree, node * 2 + 1, middle, high, ql, qr, ceiling)
	pull(tree, node)
}

range_chmax :: proc "contextless" (tree: [^]Node, node, low, high, ql, qr: int, floor: i64) {
	if qr <= low || high <= ql || tree[node].min1 >= floor do return
	if ql <= low && high <= qr && tree[node].min2 > floor {
		apply_chmax(&tree[node], floor)
		return
	}
	push(tree, node, low, high)
	middle := low + (high - low) / 2
	range_chmax(tree, node * 2, low, middle, ql, qr, floor)
	range_chmax(tree, node * 2 + 1, middle, high, ql, qr, floor)
	pull(tree, node)
}

range_sum :: proc "contextless" (tree: [^]Node, node, low, high, ql, qr: int) -> i64 {
	if qr <= low || high <= ql do return 0
	if ql <= low && high <= qr do return tree[node].sum
	push(tree, node, low, high)
	middle := low + (high - low) / 2
	return range_sum(tree, node * 2, low, middle, ql, qr) + range_sum(tree, node * 2 + 1, middle, high, ql, qr)
}

@(export)
segment_tree_beats :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input_Values) do return -1
	if input[0] < 1 || input[0] > Max_Items do return -1
	n := int(input[0])
	if int(length) < n + 2 || input[n + 1] < 0 || input[n + 1] > Max_Operations do return -1
	q := int(input[n + 1])
	if int(length) != n + 2 + 4 * q do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 1] < -Value_Limit || input[i + 1] > Value_Limit do return -1
	}
	for i := 0; i < q; i += 1 {
		p := n + 2 + 4 * i
		op, left, right, argument := input[p], input[p + 1], input[p + 2], input[p + 3]
		if op < 0 || op > 3 || left < 0 || left >= right || right > i64(n) do return -1
		if op == 3 {
			if argument != 0 do return -1
		} else if argument < -Value_Limit || argument > Value_Limit do return -1
	}

	tree: [Tree_Size]Node = {}
	build(&tree[0], &input[1], 1, 0, n)
	checksum: i64 = 0
	ordinal: i64 = 0
	for i := 0; i < q; i += 1 {
		p := n + 2 + 4 * i
		left, right := int(input[p + 1]), int(input[p + 2])
		argument := input[p + 3]
		if input[p] == 0 do range_chmin(&tree[0], 1, 0, n, left, right, argument)
		else if input[p] == 1 do range_chmax(&tree[0], 1, 0, n, left, right, argument)
		else if input[p] == 2 do range_add(&tree[0], 1, 0, n, left, right, argument)
		else {
			ordinal += 1
			checksum += ordinal * (range_sum(&tree[0], 1, 0, n, left, right) + Query_Offset)
		}
	}
	return checksum
}
