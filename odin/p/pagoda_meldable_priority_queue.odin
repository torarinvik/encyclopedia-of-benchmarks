package pagoda_meldable_priority_queue

import "core:c"

MAX_QUEUES :: 8
MAX_OPERATIONS :: 64
MAX_PARSEABLE_WORDS :: c.size_t(259)
NIL :: i64(-1)

branch_stack :: proc "contextless" (root: i64, right_branch: bool,
		node_count: int, leftmost, rightmost, stack: [^]i64) -> int {
	node := leftmost[root]
	if right_branch { node = rightmost[root] }
	if node < 0 || node >= i64(node_count) do return -1
	count := 0
	for count < node_count {
		stack[count] = node
		count += 1
		if node == root do return count
		if right_branch { node = rightmost[node] } else { node = leftmost[node] }
		if node < 0 || node >= i64(node_count) do return -1
	}
	return -1
}

pagoda_meld :: proc "contextless" (g_root, d_root: i64, node_count: int,
		keys, leftmost, rightmost: [^]i64) -> i64 {
	if g_root < 0 do return d_root
	if d_root < 0 do return g_root
	gb: [MAX_OPERATIONS]i64
	db: [MAX_OPERATIONS]i64
	gc := branch_stack(g_root, true, node_count, leftmost, rightmost, &gb[0])
	dc := branch_stack(d_root, false, node_count, leftmost, rightmost, &db[0])
	if gc < 1 || dc < 1 do return -2
	gi, di := 0, 0
	central, central_left, central_right := NIL, NIL, NIL
	for gi < gc || di < dc {
		take_g := di >= dc || (gi < gc && keys[gb[gi]] > keys[db[di]])
		node, kept := i64(-1), i64(-1)
		if take_g {
			node = gb[gi]
			gi += 1
			kept = leftmost[node]
		} else {
			node = db[di]
			di += 1
			kept = rightmost[node]
		}
		if central >= 0 {
			if take_g {
				rightmost[central] = node
				leftmost[central] = central_left
				if central_left == central { leftmost[central] = NIL }
			} else {
				leftmost[central] = node
				rightmost[central] = central_right
				if central_right == central { rightmost[central] = NIL }
			}
		}
		new_left, new_right := i64(-1), i64(-1)
		if take_g {
			new_left = kept
			if new_left < 0 { new_left = node }
			new_right = node
			if central >= 0 { new_right = central_right }
		} else {
			new_left = node
			if central >= 0 { new_left = central_left }
			new_right = kept
			if new_right < 0 { new_right = node }
		}
		leftmost[node] = new_left
		rightmost[node] = new_right
		central, central_left, central_right = node, new_left, new_right
	}
	return central
}

pagoda_extract_min :: proc "contextless" (root: i64, node_count: int,
		keys, leftmost, rightmost: [^]i64) -> i64 {
	old_left, old_right := leftmost[root], rightmost[root]
	left_child, right_child := NIL, NIL
	if old_left != root {
		node, steps := old_left, 0
		for node >= 0 && node < i64(node_count) && leftmost[node] != root && steps < node_count {
			node = leftmost[node]
			steps += 1
		}
		if node < 0 || node >= i64(node_count) || leftmost[node] != root do return -2
		left_child = node
	}
	if old_right != root {
		node, steps := old_right, 0
		for node >= 0 && node < i64(node_count) && rightmost[node] != root && steps < node_count {
			node = rightmost[node]
			steps += 1
		}
		if node < 0 || node >= i64(node_count) || rightmost[node] != root do return -2
		right_child = node
	}
	if left_child >= 0 {
		leftmost[left_child] = old_left
		if rightmost[left_child] < 0 { rightmost[left_child] = left_child }
	}
	if right_child >= 0 {
		rightmost[right_child] = old_right
		if leftmost[right_child] < 0 { leftmost[right_child] = right_child }
	}
	new_root := pagoda_meld(right_child, left_child, node_count, keys, leftmost, rightmost)
	leftmost[root] = NIL
	rightmost[root] = NIL
	return new_root
}

@(export)
pagoda_meldable_priority_queue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_WORDS do return -1
	queue_count, operation_count := input[0], input[1]
	if queue_count < 1 || queue_count > MAX_QUEUES || operation_count < 0 ||
		operation_count > MAX_OPERATIONS || length != c.size_t(2+4*operation_count) || length > 258 do return -1

	keys: [MAX_OPERATIONS]i64
	leftmost: [MAX_OPERATIONS]i64
	rightmost: [MAX_OPERATIONS]i64
	roots: [MAX_QUEUES]i64
	for i := 0; i < MAX_OPERATIONS; i += 1 { leftmost[i] = NIL; rightmost[i] = NIL }
	for i := 0; i < MAX_QUEUES; i += 1 { roots[i] = NIL }
	node_count, result := 0, i64(0)
	for op := 0; op < int(operation_count); op += 1 {
		offset := 2+4*op
		opcode, first, second, priority := input[offset], input[offset+1], input[offset+2], input[offset+3]
		if opcode == 1 {
			if first < 0 || first >= queue_count || second != 0 || priority < -1000 || priority > 1000 || node_count >= MAX_OPERATIONS do return -1
			for i := 0; i < node_count; i += 1 { if keys[i] == priority do return -1 }
			node := i64(node_count)
			node_count += 1
			keys[node] = priority
			leftmost[node] = node
			rightmost[node] = node
			merged := pagoda_meld(roots[first], node, node_count, &keys[0], &leftmost[0], &rightmost[0])
			if merged < 0 do return -1
			roots[first] = merged
		} else if opcode == 2 {
			if first < 0 || first >= queue_count || second < 0 || second >= queue_count || first == second || priority != 0 do return -1
			merged := pagoda_meld(roots[first], roots[second], node_count, &keys[0], &leftmost[0], &rightmost[0])
			if merged == -2 do return -1
			roots[first] = merged
			roots[second] = NIL
		} else if opcode == 3 || opcode == 4 {
			if first < 0 || first >= queue_count || second != 0 || priority != 0 || roots[first] < 0 do return -1
			root := roots[first]
			result += (i64(op)+1)*(keys[root]+1001)
			if opcode == 4 {
				new_root := pagoda_extract_min(root, node_count, &keys[0], &leftmost[0], &rightmost[0])
				if new_root == -2 do return -1
				roots[first] = new_root
			}
		} else { return -1 }
	}
	return result
}
