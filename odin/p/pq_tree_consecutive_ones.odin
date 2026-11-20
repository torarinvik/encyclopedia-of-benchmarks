package pq_tree_consecutive_ones

import "core:c"

MAX_N :: 20
MAX_M :: 32
MAX_INPUT :: 35
MAX_NODES :: 128
MAX_OUTPUT :: 648
LEAF :: u8(0)
P_NODE :: u8(1)
Q_NODE :: u8(2)
WHITE :: u8(0)
BLACK :: u8(1)
MIXED :: u8(2)

Pq_Node :: struct { kind: u8, count: int, arg: u8, child: [MAX_N]u8 }
Pq_Tree :: struct {
	nodes: [MAX_NODES]Pq_Node,
	color: [MAX_NODES]u8,
	free_id: [MAX_NODES]u8,
	next_id, free_count, root: int,
}

new_node :: proc(t: ^Pq_Tree, kind: u8) -> int {
	id: int
	if t.free_count > 0 {
		t.free_count -= 1
		id = int(t.free_id[t.free_count])
	} else {
		if t.next_id >= MAX_NODES do return -1
		id = t.next_id
		t.next_id += 1
	}
	t.nodes[id] = {}
	t.nodes[id].kind = kind
	return id
}
delete_node :: proc(t: ^Pq_Tree, id: int) {
	t.nodes[id].count = 0
	t.free_id[t.free_count] = u8(id)
	t.free_count += 1
}
push :: proc(t: ^Pq_Tree, id, child: int) {
	at := t.nodes[id].count
	t.nodes[id].child[at] = u8(child)
	t.nodes[id].count += 1
}

paint :: proc(t: ^Pq_Tree, id: int, mask: u64) -> u8 {
	node := t.nodes[id]
	if node.kind == LEAF {
		t.color[id] = if (mask >> node.arg) & 1 != 0 { BLACK } else { WHITE }
		return t.color[id]
	}
	saw_white, saw_black := false, false
	for i := 0; i < node.count; i += 1 {
		shade := paint(t, int(node.child[i]), mask)
		saw_white = saw_white || shade != BLACK
		saw_black = saw_black || shade != WHITE
	}
	t.color[id] = if saw_white && saw_black { MIXED } else if saw_black { BLACK } else { WHITE }
	return t.color[id]
}
q_pattern :: proc(t: ^Pq_Tree, children: [MAX_N]u8, count: int) -> bool {
	pivot, mixed := -1, 0
	for i := 0; i < count; i += 1 {
		if t.color[int(children[i])] == MIXED { pivot = i; mixed += 1; if mixed > 1 do return false }
	}
	if mixed == 0 { for i := 0; i < count; i += 1 { if t.color[int(children[i])] == BLACK { pivot = i; break } } }
	if pivot < 0 do return false
	for i := 0; i < pivot; i += 1 { if t.color[int(children[i])] != WHITE do return false }
	for i := pivot + 1; i < count; i += 1 { if t.color[int(children[i])] != BLACK do return false }
	return true
}

split :: proc(t: ^Pq_Tree, id: int, out: ^[MAX_N]u8) -> int {
	node := t.nodes[id]
	if t.color[id] != MIXED { out[0] = u8(id); return 1 }
	old := node.child
	white, black, mixed: [MAX_N]u8
	nw, nb, nm, used := 0, 0, 0, 0
	for i := 0; i < node.count; i += 1 {
		child := old[i]
		shade := t.color[int(child)]
		if shade == WHITE { white[nw] = child; nw += 1 }
		else if shade == BLACK { black[nb] = child; nb += 1 }
		else { mixed[nm] = child; nm += 1 }
	}
	if node.kind == Q_NODE {
		if !q_pattern(t, old, node.count) {
			for left, right := 0, node.count - 1; left < right; left, right = left + 1, right - 1 { old[left], old[right] = old[right], old[left] }
			if !q_pattern(t, old, node.count) do return -1
		}
		for i := 0; i < node.count; i += 1 {
			child := int(old[i])
			if t.color[child] == MIXED {
				part: [MAX_N]u8
				part_count := split(t, child, &part)
				if part_count < 0 do return -1
				for j := 0; j < part_count; j += 1 { out[used] = part[j]; used += 1 }
			} else { out[used] = old[i]; used += 1 }
		}
	} else {
		if nm > 1 do return -1
		if nw > 0 {
			group := new_node(t, P_NODE); if group < 0 do return -1
			for i := 0; i < nw; i += 1 { push(t, group, int(white[i])) }
			out[used] = u8(group); used += 1
		}
		if nm > 0 {
			part: [MAX_N]u8
			part_count := split(t, int(mixed[0]), &part); if part_count < 0 do return -1
			for i := 0; i < part_count; i += 1 { out[used] = part[i]; used += 1 }
		}
		if nb > 0 {
			group := new_node(t, P_NODE); if group < 0 do return -1
			for i := 0; i < nb; i += 1 { push(t, group, int(black[i])) }
			out[used] = u8(group); used += 1
		}
	}
	delete_node(t, id)
	return used
}

work :: proc(t: ^Pq_Tree, id: int) -> bool {
	node := t.nodes[id]
	if t.color[id] != MIXED do return true
	old, white, black, mixed: [MAX_N]u8
	nw, nb, nm := 0, 0, 0
	for i := 0; i < node.count; i += 1 {
		old[i] = node.child[i]
		shade := t.color[int(old[i])]
		if shade == WHITE { white[nw] = old[i]; nw += 1 }
		else if shade == BLACK { black[nb] = old[i]; nb += 1 }
		else { mixed[nm] = old[i]; nm += 1 }
	}
	if node.kind == P_NODE {
		if nb == 0 && nm == 1 { return work(t, int(mixed[0])) }
		if nm > 2 do return false
		q := new_node(t, Q_NODE); if q < 0 do return false
		for i := 0; i < nw; i += 1 { t.nodes[id].child[i] = white[i] }
		t.nodes[id].child[nw] = u8(q); t.nodes[id].count = nw + 1
		if nm > 0 {
			part: [MAX_N]u8
			part_count := split(t, int(mixed[0]), &part); if part_count < 0 do return false
			for i := 0; i < part_count; i += 1 { push(t, q, int(part[i])) }
		}
		if nb > 0 {
			group := new_node(t, P_NODE); if group < 0 do return false
			for i := 0; i < nb; i += 1 { push(t, group, int(black[i])) }
			push(t, q, group)
		}
		if nm == 2 {
			part: [MAX_N]u8
			part_count := split(t, int(mixed[1]), &part); if part_count < 0 do return false
			for i := part_count - 1; i >= 0; i -= 1 { push(t, q, int(part[i])) }
		}
		return true
	}
	left, right := -1, -1
	for i := 0; i < node.count; i += 1 { if t.color[int(old[i])] != WHITE { if left < 0 { left = i }; right = i } }
	if left < 0 do return false
	for i := left + 1; i < right; i += 1 { if t.color[int(old[i])] != BLACK do return false }
	if left == right && t.color[int(old[left])] == MIXED { return work(t, int(old[left])) }
	result: [MAX_N]u8
	used := 0
	for i := 0; i < left; i += 1 { result[used] = old[i]; used += 1 }
	part: [MAX_N]u8
	part_count := split(t, int(old[left]), &part); if part_count < 0 do return false
	for i := 0; i < part_count; i += 1 { result[used] = part[i]; used += 1 }
	for i := left + 1; i < right; i += 1 { result[used] = old[i]; used += 1 }
	if right != left {
		part_count = split(t, int(old[right]), &part); if part_count < 0 do return false
		for i := part_count - 1; i >= 0; i -= 1 { result[used] = part[i]; used += 1 }
	}
	for i := right + 1; i < node.count; i += 1 { result[used] = old[i]; used += 1 }
	t.nodes[id].count = used
	for i := 0; i < used; i += 1 { t.nodes[id].child[i] = result[i] }
	return true
}

normalize :: proc(t: ^Pq_Tree, id: int) -> int {
	node := t.nodes[id]
	if node.kind == LEAF do return id
	for i := 0; i < node.count; i += 1 { t.nodes[id].child[i] = u8(normalize(t, int(node.child[i]))) }
	if t.nodes[id].count == 1 { child := int(t.nodes[id].child[0]); delete_node(t, id); return child }
	if t.nodes[id].kind == Q_NODE && t.nodes[id].count == 2 { t.nodes[id].kind = P_NODE }
	return id
}
compare_nodes :: proc(t: ^Pq_Tree, a, b: int) -> int {
	x, y := t.nodes[a], t.nodes[b]
	xarg := if x.kind == LEAF { int(x.arg) } else { x.count }
	yarg := if y.kind == LEAF { int(y.arg) } else { y.count }
	if x.kind != y.kind { return if x.kind < y.kind { -1 } else { 1 } }
	if xarg != yarg { return if xarg < yarg { -1 } else { 1 } }
	if x.kind != LEAF { for i := 0; i < x.count; i += 1 { c := compare_nodes(t, int(x.child[i]), int(y.child[i])); if c != 0 do return c } }
	return 0
}
canonicalize :: proc(t: ^Pq_Tree, id: int) {
	node := t.nodes[id]
	if node.kind == LEAF do return
	for i := 0; i < node.count; i += 1 { canonicalize(t, int(node.child[i])) }
	if node.kind == P_NODE {
		for i := 1; i < node.count; i += 1 { item := t.nodes[id].child[i]; j := i; for j > 0 && compare_nodes(t, int(item), int(t.nodes[id].child[j-1])) < 0 { t.nodes[id].child[j] = t.nodes[id].child[j-1]; j -= 1 }; t.nodes[id].child[j] = item }
	} else {
		order := 0
		for i := 0; i < node.count; i += 1 { order = compare_nodes(t, int(node.child[i]), int(node.child[node.count-1-i])); if order != 0 do break }
		if order > 0 { for left, right := 0, node.count-1; left < right; left, right = left+1, right-1 { t.nodes[id].child[left], t.nodes[id].child[right] = t.nodes[id].child[right], t.nodes[id].child[left] } }
	}
}
frontier_count :: proc(t: ^Pq_Tree, id: int) -> i64 {
	node := t.nodes[id]; if node.kind == LEAF do return 1
	result: i64 = 1
	for i := 0; i < node.count; i += 1 { result *= frontier_count(t, int(node.child[i])) }
	if node.kind == P_NODE { for factor := 2; factor <= node.count; factor += 1 { result *= i64(factor) } } else { result *= 2 }
	return result
}
node_count :: proc(t: ^Pq_Tree, id: int) -> int { node := t.nodes[id]; count := 1; if node.kind != LEAF { for i := 0; i < node.count; i += 1 { count += node_count(t, int(node.child[i])) } }; return count }
serialize :: proc(t: ^Pq_Tree, id: int, words: ^[81]i64, used: ^int) {
	node := t.nodes[id]; words[used^] = i64(node.kind); used^ += 1; words[used^] = if node.kind == LEAF { i64(node.arg) } else { i64(node.count) }; used^ += 1
	if node.kind != LEAF { for i := 0; i < node.count; i += 1 { serialize(t, int(node.child[i]), words, used) } }
}
store_i64 :: proc(output: [^]u8, offset: int, value: i64) { bits := u64(value); for i := 0; i < 8; i += 1 { output[offset+i] = u8((bits >> (8*i)) & 255) } }

@(export)
pq_tree_consecutive_ones :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nraw, mraw := input[0], input[1]
	if nraw < 2 || nraw > MAX_N || mraw < 0 || mraw > MAX_M || length != c.size_t(2+mraw) do return -1
	n, m := int(nraw), int(mraw)
	valid := (u64(1) << n) - 1
	for row := 0; row < m; row += 1 { raw := input[2+row]; if raw < 0 || (u64(raw) & ~valid) != 0 do return -1 }
	tree: Pq_Tree = {}
	tree.next_id = n+1; tree.root = n
	for i := 0; i < n; i += 1 { tree.nodes[i].kind = LEAF; tree.nodes[i].arg = u8(i); tree.nodes[n].child[i] = u8(i) }
	tree.nodes[n].kind = P_NODE; tree.nodes[n].count = n
	for row := 0; row < m; row += 1 {
		_ = paint(&tree, tree.root, u64(input[2+row]))
		if !work(&tree, tree.root) {
			if output == nil || capacity < 24 do return -2
			for i := 0; i < 24; i += 1 { output[i] = 0 }
			return 24
		}
		tree.root = normalize(&tree, tree.root)
	}
	canonicalize(&tree, tree.root)
	words: [81]i64 = {}; used := 0
	words[used] = 1; used += 1; words[used] = frontier_count(&tree, tree.root); used += 1; words[used] = i64(node_count(&tree, tree.root)); used += 1
	serialize(&tree, tree.root, &words, &used)
	staged: [MAX_OUTPUT]u8 = {}
	for i := 0; i < used; i += 1 { store_i64(&staged[0], 8*i, words[i]) }
	bytes := used*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
