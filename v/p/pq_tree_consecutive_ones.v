module pq_tree_consecutive_ones

import core.c

const max_n = 20
const max_m = 32
const max_input = 35
const max_nodes = 128
const max_output = 648
const leaf = u8(0)
const p_node = u8(1)
const q_node = u8(2)
const white = u8(0)
const black = u8(1)
const mixed = u8(2)

struct PqNode {
	kind u8
	count int
	arg u8
	child [max_n]u8
}

struct PqTree {
	nodes [max_nodes]PqNode
	color [max_nodes]u8
	free_id [max_nodes]u8
	next_id int
	free_count int
	root int
}

fn pq_new(mut t &PqTree, kind u8) int {
	mut id := 0
	if t.free_count > 0 {
		t.free_count--
		id = int(t.free_id[t.free_count])
	} else {
		if t.next_id >= max_nodes { return -1 }
		id = t.next_id
		t.next_id++
	}
	t.nodes[id] = PqNode{}
	t.nodes[id].kind = kind
	return id
}

fn pq_delete(mut t &PqTree, id int) {
	t.nodes[id].count = 0
	t.free_id[t.free_count] = u8(id)
	t.free_count++
}

fn pq_push(mut t &PqTree, id int, child int) {
	index := t.nodes[id].count
	t.nodes[id].child[index] = u8(child)
	t.nodes[id].count++
}

fn pq_paint(mut t &PqTree, id int, mask u64) u8 {
	node := t.nodes[id]
	if node.kind == leaf {
		t.color[id] = if ((mask >> node.arg) & 1) != 0 { black } else { white }
		return t.color[id]
	}
	mut saw_white := false
	mut saw_black := false
	for i in 0 .. node.count {
		shade := pq_paint(mut t, int(node.child[i]), mask)
		saw_white = saw_white || shade != black
		saw_black = saw_black || shade != white
	}
	t.color[id] = if saw_white && saw_black { mixed } else if saw_black { black } else { white }
	return t.color[id]
}

fn pq_pattern(t &PqTree, children [max_n]u8, count int) bool {
	mut pivot := -1
	mut gray := 0
	for i in 0 .. count {
		if t.color[int(children[i])] == mixed {
			pivot = i
			gray++
			if gray > 1 { return false }
		}
	}
	if gray == 0 {
		for i in 0 .. count {
			if t.color[int(children[i])] == black { pivot = i; break }
		}
	}
	if pivot < 0 { return false }
	for i in 0 .. pivot { if t.color[int(children[i])] != white { return false } }
	for i in pivot + 1 .. count { if t.color[int(children[i])] != black { return false } }
	return true
}

fn pq_split(mut t &PqTree, id int, mut output [max_n]u8) int {
	node := t.nodes[id]
	if t.color[id] != mixed { output[0] = u8(id); return 1 }
	mut old := node.child
	mut whites := [max_n]u8{}
	mut blacks := [max_n]u8{}
	mut grays := [max_n]u8{}
	mut nw := 0
	mut nb := 0
	mut ng := 0
	mut used := 0
	for i in 0 .. node.count {
		child := old[i]
		shade := t.color[int(child)]
		if shade == white { whites[nw] = child; nw++ }
		else if shade == black { blacks[nb] = child; nb++ }
		else { grays[ng] = child; ng++ }
	}
	if node.kind == q_node {
		if !pq_pattern(t, old, node.count) {
			for left, right := 0, node.count - 1; left < right; left, right = left + 1, right - 1 { old[left], old[right] = old[right], old[left] }
			if !pq_pattern(t, old, node.count) { return -1 }
		}
		for i in 0 .. node.count {
			child := int(old[i])
			if t.color[child] == mixed {
				mut part := [max_n]u8{}
				part_count := pq_split(mut t, child, mut part)
				if part_count < 0 { return -1 }
				for j in 0 .. part_count { output[used] = part[j]; used++ }
			} else { output[used] = old[i]; used++ }
		}
	} else {
		if ng > 1 { return -1 }
		if nw > 0 {
			group := pq_new(mut t, p_node)
			if group < 0 { return -1 }
			for i in 0 .. nw { pq_push(mut t, group, int(whites[i])) }
			output[used] = u8(group); used++
		}
		if ng > 0 {
			mut part := [max_n]u8{}
			part_count := pq_split(mut t, int(grays[0]), mut part)
			if part_count < 0 { return -1 }
			for i in 0 .. part_count { output[used] = part[i]; used++ }
		}
		if nb > 0 {
			group := pq_new(mut t, p_node)
			if group < 0 { return -1 }
			for i in 0 .. nb { pq_push(mut t, group, int(blacks[i])) }
			output[used] = u8(group); used++
		}
	}
	pq_delete(mut t, id)
	return used
}

fn pq_work(mut t &PqTree, id int) bool {
	node := t.nodes[id]
	if t.color[id] != mixed { return true }
	mut old := [max_n]u8{}
	mut whites := [max_n]u8{}
	mut blacks := [max_n]u8{}
	mut grays := [max_n]u8{}
	mut nw := 0
	mut nb := 0
	mut ng := 0
	for i in 0 .. node.count {
		old[i] = node.child[i]
		shade := t.color[int(old[i])]
		if shade == white { whites[nw] = old[i]; nw++ }
		else if shade == black { blacks[nb] = old[i]; nb++ }
		else { grays[ng] = old[i]; ng++ }
	}
	if node.kind == p_node {
		if nb == 0 && ng == 1 { return pq_work(mut t, int(grays[0])) }
		if ng > 2 { return false }
		q := pq_new(mut t, q_node)
		if q < 0 { return false }
		for i in 0 .. nw { t.nodes[id].child[i] = whites[i] }
		t.nodes[id].child[nw] = u8(q)
		t.nodes[id].count = nw + 1
		if ng > 0 {
			mut part := [max_n]u8{}
			part_count := pq_split(mut t, int(grays[0]), mut part)
			if part_count < 0 { return false }
			for i in 0 .. part_count { pq_push(mut t, q, int(part[i])) }
		}
		if nb > 0 {
			group := pq_new(mut t, p_node)
			if group < 0 { return false }
			for i in 0 .. nb { pq_push(mut t, group, int(blacks[i])) }
			pq_push(mut t, q, group)
		}
		if ng == 2 {
			mut part := [max_n]u8{}
			part_count := pq_split(mut t, int(grays[1]), mut part)
			if part_count < 0 { return false }
			for i := part_count - 1; i >= 0; i-- { pq_push(mut t, q, int(part[i])) }
		}
		return true
	}
	mut left := -1
	mut right := -1
	for i in 0 .. node.count { if t.color[int(old[i])] != white { if left < 0 { left = i }; right = i } }
	if left < 0 { return false }
	for i in left + 1 .. right { if t.color[int(old[i])] != black { return false } }
	if left == right && t.color[int(old[left])] == mixed { return pq_work(mut t, int(old[left])) }
	mut result := [max_n]u8{}
	mut used := 0
	for i in 0 .. left { result[used] = old[i]; used++ }
	mut part := [max_n]u8{}
	mut part_count := pq_split(mut t, int(old[left]), mut part)
	if part_count < 0 { return false }
	for i in 0 .. part_count { result[used] = part[i]; used++ }
	for i in left + 1 .. right { result[used] = old[i]; used++ }
	if right != left {
		part_count = pq_split(mut t, int(old[right]), mut part)
		if part_count < 0 { return false }
		for i := part_count - 1; i >= 0; i-- { result[used] = part[i]; used++ }
	}
	for i in right + 1 .. node.count { result[used] = old[i]; used++ }
	t.nodes[id].count = used
	for i in 0 .. used { t.nodes[id].child[i] = result[i] }
	return true
}

fn pq_normalize(mut t &PqTree, id int) int {
	node := t.nodes[id]
	if node.kind == leaf { return id }
	for i in 0 .. node.count { t.nodes[id].child[i] = u8(pq_normalize(mut t, int(node.child[i]))) }
	if t.nodes[id].count == 1 { child := int(t.nodes[id].child[0]); pq_delete(mut t, id); return child }
	if t.nodes[id].kind == q_node && t.nodes[id].count == 2 { t.nodes[id].kind = p_node }
	return id
}

fn pq_compare(t &PqTree, a int, b int) int {
	x, y := t.nodes[a], t.nodes[b]
	x_arg := if x.kind == leaf { int(x.arg) } else { x.count }
	y_arg := if y.kind == leaf { int(y.arg) } else { y.count }
	if x.kind != y.kind { return if x.kind < y.kind { -1 } else { 1 } }
	if x_arg != y_arg { return if x_arg < y_arg { -1 } else { 1 } }
	if x.kind != leaf { for i in 0 .. x.count { cmp := pq_compare(t, int(x.child[i]), int(y.child[i])); if cmp != 0 { return cmp } } }
	return 0
}

fn pq_canonicalize(mut t &PqTree, id int) {
	node := t.nodes[id]
	if node.kind == leaf { return }
	for i in 0 .. node.count { pq_canonicalize(mut t, int(node.child[i])) }
	if node.kind == p_node {
		for i in 1 .. node.count {
			item := t.nodes[id].child[i]
			mut j := i
			for j > 0 && pq_compare(t, int(item), int(t.nodes[id].child[j - 1])) < 0 { t.nodes[id].child[j] = t.nodes[id].child[j - 1]; j-- }
			t.nodes[id].child[j] = item
		}
	} else {
		mut order := 0
		for i in 0 .. node.count { order = pq_compare(t, int(node.child[i]), int(node.child[node.count - 1 - i])); if order != 0 { break } }
		if order > 0 { for left, right := 0, node.count - 1; left < right; left++, right-- { t.nodes[id].child[left], t.nodes[id].child[right] = t.nodes[id].child[right], t.nodes[id].child[left] } }
	}
}

fn pq_frontier_count(t &PqTree, id int) i64 {
	node := t.nodes[id]
	if node.kind == leaf { return 1 }
	mut result := i64(1)
	for i in 0 .. node.count { result *= pq_frontier_count(t, int(node.child[i])) }
	if node.kind == p_node { for factor in 2 .. node.count + 1 { result *= i64(factor) } } else { result *= 2 }
	return result
}
fn pq_node_count(t &PqTree, id int) int { node := t.nodes[id]; mut count := 1; if node.kind != leaf { for i in 0 .. node.count { count += pq_node_count(t, int(node.child[i])) } }; return count }
fn pq_serialize(t &PqTree, id int, mut words [81]i64, mut used int) {
	node := t.nodes[id]
	words[used] = i64(node.kind); used++
	words[used] = if node.kind == leaf { i64(node.arg) } else { i64(node.count) }; used++
	if node.kind != leaf { for i in 0 .. node.count { pq_serialize(t, int(node.child[i]), mut words, mut used) } }
}
fn pq_store_i64(mut output &u8, offset int, value i64) { bits := u64(value); for i in 0 .. 8 { output[offset + i] = u8((bits >> (8 * i)) & 255) } }

@[export: 'pq_tree_consecutive_ones']
pub fn pq_tree_consecutive_ones(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_raw, m_raw := input[0], input[1]
		if n_raw < 2 || n_raw > max_n || m_raw < 0 || m_raw > max_m || length != usize(2 + m_raw) { return -1 }
		n, m := int(n_raw), int(m_raw)
		valid := (u64(1) << n) - 1
		for row in 0 .. m { raw := input[2 + row]; if raw < 0 || (u64(raw) & ~valid) != 0 { return -1 } }
		mut tree := PqTree{}
		tree.next_id = n + 1
		tree.root = n
		for i in 0 .. n { tree.nodes[i].kind = leaf; tree.nodes[i].arg = u8(i); tree.nodes[n].child[i] = u8(i) }
		tree.nodes[n].kind = p_node
		tree.nodes[n].count = n
		for row in 0 .. m {
			_ = pq_paint(mut tree, tree.root, u64(input[2 + row]))
			if !pq_work(mut tree, tree.root) {
				if output == nil || capacity < 24 { return -2 }
				for i in 0 .. 24 { output[i] = 0 }
				return 24
			}
			tree.root = pq_normalize(mut tree, tree.root)
		}
		pq_canonicalize(mut tree, tree.root)
		mut words := [81]i64{}
		mut used := 0
		words[used] = 1; used++
		words[used] = pq_frontier_count(tree, tree.root); used++
		words[used] = i64(pq_node_count(tree, tree.root)); used++
		pq_serialize(tree, tree.root, mut words, mut used)
		mut staged := [max_output]u8{}
		for i in 0 .. used { pq_store_i64(mut &staged[0], 8 * i, words[i]) }
		bytes := used * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
