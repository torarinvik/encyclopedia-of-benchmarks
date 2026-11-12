module dynamic_tree_subtree_add_subtree_sum

const max_n = 16
const max_q = 32
const max_tokens = max_n + 2 * (max_n - 1 + max_q)
const max_input = 3 * max_n + 5 * max_q + 1
const max_delta = i64(1000)

struct TourNode {
mut:
	left int
	right int
	parent int
	priority u32
	sequence_size int
	marker_count int
	marker bool
	own_value i64
	sum i64
	lazy_add i64
}
struct Tour {
mut:
	nodes [max_tokens]TourNode
	next_node int
	random_state u32
}
struct EdgeTokens {
	forward int
	reverse int
}

fn seq_size(tour &Tour, id int) int {
	if id < 0 { return 0 }
	return tour.nodes[id].sequence_size
}
fn marker_count(tour &Tour, id int) int {
	if id < 0 { return 0 }
	return tour.nodes[id].marker_count
}
fn node_sum(tour &Tour, id int) i64 {
	if id < 0 { return 0 }
	return tour.nodes[id].sum
}
fn pull(mut tour Tour, id int) {
	n := tour.nodes[id]
	tour.nodes[id].sequence_size = 1 + seq_size(tour, n.left) + seq_size(tour, n.right)
	tour.nodes[id].marker_count = int(n.marker) + marker_count(tour, n.left) + marker_count(tour, n.right)
	tour.nodes[id].sum = n.own_value + node_sum(tour, n.left) + node_sum(tour, n.right)
}
fn apply_add(mut tour Tour, id int, delta i64) {
	if id < 0 || tour.nodes[id].marker_count == 0 { return }
	tour.nodes[id].sum += delta * i64(tour.nodes[id].marker_count)
	if tour.nodes[id].marker { tour.nodes[id].own_value += delta }
	tour.nodes[id].lazy_add += delta
}
fn push(mut tour Tour, id int) {
	delta := tour.nodes[id].lazy_add
	if delta == 0 { return }
	apply_add(mut tour, tour.nodes[id].left, delta)
	apply_add(mut tour, tour.nodes[id].right, delta)
	tour.nodes[id].lazy_add = 0
}
fn next_priority(mut tour Tour) u32 {
	mut x := tour.random_state
	x ^= x << 13
	x ^= x >> 17
	x ^= x << 5
	tour.random_state = x
	return x
}
fn new_node(mut tour Tour, marker bool, value i64) int {
	if tour.next_node >= max_tokens { return -1 }
	id := tour.next_node
	tour.next_node++
	tour.nodes[id] = TourNode{
		left: -1, right: -1, parent: -1, priority: next_priority(mut tour),
		sequence_size: 1, marker_count: int(marker), marker: marker,
		own_value: if marker { value } else { i64(0) },
		sum: if marker { value } else { i64(0) },
	}
	return id
}
fn split(mut tour Tour, root int, count int) (int, int) {
	if root < 0 { return -1, -1 }
	push(mut tour, root)
	tour.nodes[root].parent = -1
	left := tour.nodes[root].left
	if seq_size(tour, left) >= count {
		first, middle := split(mut tour, left, count)
		tour.nodes[root].left = middle
		if middle >= 0 { tour.nodes[middle].parent = root }
		pull(mut tour, root)
		if first >= 0 { tour.nodes[first].parent = -1 }
		tour.nodes[root].parent = -1
		return first, root
	}
	right := tour.nodes[root].right
	middle, second := split(mut tour, right, count - seq_size(tour, left) - 1)
	tour.nodes[root].right = middle
	if middle >= 0 { tour.nodes[middle].parent = root }
	pull(mut tour, root)
	tour.nodes[root].parent = -1
	if second >= 0 { tour.nodes[second].parent = -1 }
	return root, second
}
fn merge(mut tour Tour, first int, second int) int {
	if first < 0 {
		if second >= 0 { tour.nodes[second].parent = -1 }
		return second
	}
	if second < 0 { tour.nodes[first].parent = -1; return first }
	tour.nodes[first].parent = -1
	tour.nodes[second].parent = -1
	if tour.nodes[first].priority >= tour.nodes[second].priority {
		push(mut tour, first)
		joined := merge(mut tour, tour.nodes[first].right, second)
		tour.nodes[first].right = joined
		if joined >= 0 { tour.nodes[joined].parent = first }
		pull(mut tour, first)
		tour.nodes[first].parent = -1
		return first
	}
	push(mut tour, second)
	joined := merge(mut tour, first, tour.nodes[second].left)
	tour.nodes[second].left = joined
	if joined >= 0 { tour.nodes[joined].parent = second }
	pull(mut tour, second)
	tour.nodes[second].parent = -1
	return second
}
fn root_of(tour &Tour, start int) int {
	mut id := start
	for tour.nodes[id].parent >= 0 { id = tour.nodes[id].parent }
	return id
}
fn rank_of(tour &Tour, start int) int {
	mut id := start
	mut rank := seq_size(tour, tour.nodes[id].left)
	for tour.nodes[id].parent >= 0 {
		parent := tour.nodes[id].parent
		if tour.nodes[parent].right == id { rank += 1 + seq_size(tour, tour.nodes[parent].left) }
		id = parent
	}
	return rank
}
fn rotate_to(mut tour Tour, id int) int {
	first, second := split(mut tour, root_of(tour, id), rank_of(tour, id))
	return merge(mut tour, second, first)
}
fn link_tours(mut tour Tour, markers [max_n]int, u int, v int) ?EdgeTokens {
	root_u := root_of(tour, markers[u])
	root_v := root_of(tour, markers[v])
	if root_u == root_v { return none }
	a0, a1 := split(mut tour, root_u, rank_of(tour, markers[u]) + 1)
	b0, tail := split(mut tour, root_v, rank_of(tour, markers[v]))
	vm, b1 := split(mut tour, tail, 1)
	uv := new_node(mut tour, false, 0)
	vu := new_node(mut tour, false, 0)
	if uv < 0 || vu < 0 { return none }
	mut root := merge(mut tour, a0, uv)
	root = merge(mut tour, root, b1)
	root = merge(mut tour, root, b0)
	root = merge(mut tour, root, vm)
	root = merge(mut tour, root, vu)
	_ = merge(mut tour, root, a1)
	return EdgeTokens{forward: uv, reverse: vu}
}
fn cut_tours(mut tour Tour, uv int, vu int) bool {
	root := rotate_to(mut tour, uv)
	reverse_rank := rank_of(tour, vu)
	if reverse_rank == 0 { return false }
	first, rest := split(mut tour, root, 1)
	_, tail := split(mut tour, rest, reverse_rank - 1)
	reverse, _ := split(mut tour, tail, 1)
	if first != uv || reverse != vu { return false }
	tour.nodes[uv].left = -1; tour.nodes[uv].right = -1; tour.nodes[uv].parent = -1
	tour.nodes[vu].left = -1; tour.nodes[vu].right = -1; tour.nodes[vu].parent = -1
	return true
}
fn side_operation(mut tour Tour, uv int, vu int, update bool, delta i64, answer &i64) bool {
	root := rotate_to(mut tour, uv)
	reverse_rank := rank_of(tour, vu)
	if reverse_rank == 0 { return false }
	edge, rest := split(mut tour, root, 1)
	side, tail := split(mut tour, rest, reverse_rank - 1)
	if edge != uv || side < 0 { return false }
	if update { apply_add(mut tour, side, delta) } else { unsafe { answer[0] = node_sum(tour, side) } }
	joined := merge(mut tour, edge, side)
	_ = merge(mut tour, joined, tail)
	return true
}
fn connected(adjacency [max_n * max_n]bool, n int, start int, goal int) bool {
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	queue[0] = start
	seen[start] = true
	for head < tail {
		u := queue[head]
		head++
		if u == goal { return true }
		for v in 0 .. n {
			if adjacency[u * max_n + v] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	return false
}
fn validate_fields(input &i64, n int, q int, queries &int) bool {
	unsafe {
		for i in 0 .. n { if input[2 + i] < 0 || input[2 + i] > max_delta { return false } }
		edge_start := 2 + n
		for i in 0 .. (n - 1) {
			u := input[edge_start + 2 * i]; v := input[edge_start + 2 * i + 1]
			if u < 0 || u >= i64(n) || v < 0 || v >= i64(n) || u == v { return false }
		}
		operations := edge_start + 2 * (n - 1)
		unsafe { queries[0] = 0 }
		for i in 0 .. q {
			at := operations + 5 * i
			kind := input[at]; v := input[at + 1]; p := input[at + 2]; a := input[at + 3]; b := input[at + 4]
			if kind == 0 {
				if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || a < 0 || a >= i64(n) || b < 0 || b >= i64(n) || v == p || a == b { return false }
			} else if kind == 1 {
				if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || v == p || a < 0 || a > max_delta || b != 0 { return false }
			} else if kind == 2 {
				if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || v == p || a != 0 || b != 0 { return false }
				unsafe { queries[0]++ }
			} else { return false }
		}
	}
	return true
}
fn validate_topology(input &i64, n int, q int) bool {
	unsafe {
		mut adjacency := [max_n * max_n]bool{}
		edge_start := 2 + n
		operations := edge_start + 2 * (n - 1)
		for i in 0 .. (n - 1) {
			u := int(input[edge_start + 2 * i]); v := int(input[edge_start + 2 * i + 1])
			if adjacency[u * max_n + v] { return false }
			adjacency[u * max_n + v] = true; adjacency[v * max_n + u] = true
		}
		for v in 0 .. n { if !connected(adjacency, n, 0, v) { return false } }
		for i in 0 .. q {
			at := operations + 5 * i
			kind := int(input[at]); v := int(input[at + 1]); p := int(input[at + 2])
			if kind == 0 {
				a := int(input[at + 3]); b := int(input[at + 4])
				if !adjacency[v * max_n + p] { return false }
				adjacency[v * max_n + p] = false; adjacency[p * max_n + v] = false
				if connected(adjacency, n, a, b) { return false }
				adjacency[a * max_n + b] = true; adjacency[b * max_n + a] = true
			} else if !adjacency[v * max_n + p] { return false }
		}
	}
	return true
}
fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'dynamic_tree_subtree_add_subtree_sum']
pub fn dynamic_tree_subtree_add_subtree_sum(input &i64, input_length usize,
	mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_input) { return -1 }
		n_value := input[0]; q_value := input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n := int(n_value); q := int(q_value)
		if input_length != usize(3 * n + 5 * q) { return -1 }
		mut queries := 0
		if !validate_fields(input, n, q, &queries) || !validate_topology(input, n, q) { return -1 }
		output_bytes := 8 * queries
		if output_bytes > 0 && (output == nil || output_capacity < usize(output_bytes)) { return -2 }
		mut tour := Tour{random_state: u32(0x9e3779b9)}
		mut markers := [max_n]int{}
		for i in 0 .. n { markers[i] = new_node(mut tour, true, input[2 + i]) }
		mut directed := [max_n * max_n]int{}
		for i in 0 .. directed.len { directed[i] = -1 }
		edge_start := 2 + n; operations := edge_start + 2 * (n - 1)
		for i in 0 .. (n - 1) {
			u := int(input[edge_start + 2 * i]); v := int(input[edge_start + 2 * i + 1])
			edge := link_tours(mut tour, markers, u, v) or { return -1 }
			directed[u * max_n + v] = edge.forward; directed[v * max_n + u] = edge.reverse
		}
		mut answers := [max_q]i64{}
		mut answer_count := 0
		for i in 0 .. q {
			at := operations + 5 * i
			kind := int(input[at]); v := int(input[at + 1]); p := int(input[at + 2])
			if kind == 0 {
				a := int(input[at + 3]); b := int(input[at + 4])
				uv := directed[v * max_n + p]; vu := directed[p * max_n + v]
				if uv < 0 || vu < 0 || !cut_tours(mut tour, uv, vu) { return -1 }
				directed[v * max_n + p] = -1; directed[p * max_n + v] = -1
				edge := link_tours(mut tour, markers, a, b) or { return -1 }
				directed[a * max_n + b] = edge.forward; directed[b * max_n + a] = edge.reverse
			} else if kind == 1 {
				mut ignored := i64(0)
				if !side_operation(mut tour, directed[p * max_n + v], directed[v * max_n + p], true, input[at + 3], &ignored) { return -1 }
			} else {
				mut answer := i64(0)
				if !side_operation(mut tour, directed[p * max_n + v], directed[v * max_n + p], false, 0, &answer) { return -1 }
				answers[answer_count] = answer; answer_count++
			}
		}
		for i in 0 .. answer_count { put_i64(mut output, 8 * i, answers[i]) }
		return i64(output_bytes)
	}
}
