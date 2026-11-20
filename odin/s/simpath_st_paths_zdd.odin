package simpath_st_paths_zdd

import "core:c"

MAX_N :: 8
MAX_M :: 9
MAX_STATES :: 1023
MAX_ZDD :: 511
MAX_INPUT :: 23
RADIX :: i64(2048)

Edge :: struct { u, v: int }
Memo :: struct { level: int, mate: [MAX_N]u8, result: int }
ZNode :: struct { level, low, high: int }
Context :: struct {
	n, m, source, target, memo_count, node_count: int,
	edges: [MAX_M]Edge,
	last: [MAX_N]int,
	memo: [MAX_STATES]Memo,
	nodes: [MAX_ZDD]ZNode,
}

degree_of :: proc(mate: [MAX_N]u8, vertex: int) -> int {
	if int(mate[vertex]) == vertex + 1 do return 0
	if mate[vertex] == 0 do return 2
	return 1
}

// Status: 0 is pruned, 1 is a suffix state, 2 is the one-terminal.
transition :: proc(c: ^Context, level: int, mate: [MAX_N]u8, selected: bool) -> (int, [MAX_N]u8) {
	next := mate
	if selected {
		u, v := c.edges[level].u, c.edges[level].v
		du, dv := degree_of(next, u), degree_of(next, v)
		if du == 2 || dv == 2 do return 0, next
		if (u == c.source || u == c.target) && du == 1 do return 0, next
		if (v == c.source || v == c.target) && dv == 1 do return 0, next
		mu, mv := int(next[u]), int(next[v])
		if mu == v + 1 && mv == u + 1 do return 0, next
		if (mu == c.source + 1 && mv == c.target + 1) || (mu == c.target + 1 && mv == c.source + 1) {
			for w := 0; w < c.n; w += 1 {
				if w != c.source && w != c.target && w != u && w != v && degree_of(next, w) == 1 do return 0, next
			}
			return 2, next
		}
		next[u], next[v] = 0, 0
		next[mu - 1], next[mv - 1] = u8(mv), u8(mu)
	}
	for w := 0; w < c.n; w += 1 {
		if c.last[w] != level do continue
		degree := degree_of(next, w)
		if w == c.source || w == c.target {
			if degree == 0 do return 0, next
		} else {
			if degree == 1 do return 0, next
			next[w] = u8(w + 1)
		}
	}
	return 1, next
}

memo_find :: proc(c: ^Context, level: int, mate: [MAX_N]u8) -> int {
	for i := 0; i < c.memo_count; i += 1 {
		entry := c.memo[i]
		if entry.level != level do continue
		equal := true
		for v := 0; v < c.n; v += 1 { if entry.mate[v] != mate[v] { equal = false; break } }
		if equal do return entry.result
	}
	return -1
}

make_node :: proc(c: ^Context, level, low, high: int) -> int {
	if high == 0 do return low
	for i := 0; i < c.node_count; i += 1 {
		node := c.nodes[i]
		if node.level == level && node.low == low && node.high == high do return i + 2
	}
	if c.node_count >= MAX_ZDD do return -1
	c.nodes[c.node_count] = ZNode{level, low, high}
	c.node_count += 1
	return c.node_count + 1
}

solve :: proc(c: ^Context, level: int, mate: [MAX_N]u8) -> int {
	if level == c.m do return 0
	cached := memo_find(c, level, mate)
	if cached >= 0 do return cached
	low_status, low_state := transition(c, level, mate, false)
	low := 0
	if low_status != 0 do low = solve(c, level + 1, low_state)
	high_status, high_state := transition(c, level, mate, true)
	high := 0
	if high_status == 2 do high = 1 else if high_status == 1 do high = solve(c, level + 1, high_state)
	result := make_node(c, level, low, high)
	if result < 0 || c.memo_count >= MAX_STATES do return -1
	c.memo[c.memo_count] = Memo{level, mate, result}
	c.memo_count += 1
	return result
}

reachable_nodes :: proc(c: ^Context, root: int) -> int {
	seen: [MAX_ZDD + 2]bool
	stack: [2 * MAX_ZDD + 3]int
	top, count := 1, 0
	stack[0] = root
	for top > 0 {
		top -= 1
		id := stack[top]
		if id <= 1 || seen[id] do continue
		seen[id] = true
		count += 1
		node := c.nodes[id - 2]
		stack[top], top = node.low, top + 1
		stack[top], top = node.high, top + 1
	}
	return count
}

@(export)
simpath_st_paths_zdd :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64, m64, s64, t64 := input[0], input[1], input[2], input[3]
	if n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || s64 < 0 || s64 >= n64 || t64 < 0 || t64 >= n64 || s64 == t64 || length != c.size_t(4 + 2 * m64) do return -1
	c := Context{n=int(n64), m=int(m64), source=int(s64), target=int(t64)}
	for v := 0; v < c.n; v += 1 { c.last[v] = -1 }
	for i := 0; i < c.m; i += 1 {
		u64, v64 := input[4 + 2 * i], input[5 + 2 * i]
		if u64 < 0 || u64 >= v64 || v64 >= n64 do return -1
		for j := 0; j < i; j += 1 { if c.edges[j].u == int(u64) && c.edges[j].v == int(v64) do return -1 }
		u, v := int(u64), int(v64)
		c.edges[i] = Edge{u, v}
		c.last[u], c.last[v] = i, i
	}
	initial: [MAX_N]u8
	for v := 0; v < c.n; v += 1 { initial[v] = u8(v + 1) }
	root := solve(&c, 0, initial)
	if root < 0 do return -1
	ways: [MAX_ZDD + 2]u16
	ways[1] = 1
	for id := 2; id < c.node_count + 2; id += 1 {
		node := c.nodes[id - 2]
		ways[id] = ways[node.low] + ways[node.high]
	}
	path_count := int(ways[root])
	if path_count >= 2048 do return -1
	return i64(reachable_nodes(&c, root)) * RADIX + i64(path_count)
}
