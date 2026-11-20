module simpath_st_paths_zdd

const max_n = 8
const max_m = 9
const max_states = 1023
const max_zdd = 511
const max_input = 23
const radix = i64(2048)

struct Edge { u int; v int }
struct Memo { level int; mate [max_n]u8; result int }
struct ZNode { level int; low int; high int }
struct Context {
	n int
	m int
	source int
	target int
	memo_count int
	node_count int
	edges [max_m]Edge
	last [max_n]int
	memo [max_states]Memo
	nodes [max_zdd]ZNode
}

fn degree_of(mate [max_n]u8, vertex int) int {
	if int(mate[vertex]) == vertex + 1 { return 0 }
	if mate[vertex] == 0 { return 2 }
	return 1
}

// 0 means pruned, 1 returns a suffix state, 2 returns the one-terminal.
fn transition(c &Context, level int, mate [max_n]u8, selected bool, mut next [max_n]u8) int {
	for i in 0 .. c.n { next[i] = mate[i] }
	if selected {
		u := c.edges[level].u
		v := c.edges[level].v
		du := degree_of(next, u)
		dv := degree_of(next, v)
		if du == 2 || dv == 2 { return 0 }
		if (u == c.source || u == c.target) && du == 1 { return 0 }
		if (v == c.source || v == c.target) && dv == 1 { return 0 }
		mu := int(next[u])
		mv := int(next[v])
		if mu == v + 1 && mv == u + 1 { return 0 }
		if (mu == c.source + 1 && mv == c.target + 1) || (mu == c.target + 1 && mv == c.source + 1) {
			for w in 0 .. c.n {
				if w != c.source && w != c.target && w != u && w != v && degree_of(next, w) == 1 { return 0 }
			}
			return 2
		}
		next[u] = 0
		next[v] = 0
		next[mu - 1] = u8(mv)
		next[mv - 1] = u8(mu)
	}
	for w in 0 .. c.n {
		if c.last[w] != level { continue }
		degree := degree_of(next, w)
		if w == c.source || w == c.target {
			if degree == 0 { return 0 }
		} else {
			if degree == 1 { return 0 }
			next[w] = u8(w + 1)
		}
	}
	return 1
}

fn memo_find(c &Context, level int, mate [max_n]u8) int {
	for i in 0 .. c.memo_count {
		entry := c.memo[i]
		if entry.level != level { continue }
		equal := true
		for v in 0 .. c.n { if entry.mate[v] != mate[v] { equal = false; break } }
		if equal { return entry.result }
	}
	return -1
}

fn make_node(mut c &Context, level int, low int, high int) int {
	if high == 0 { return low }
	for i in 0 .. c.node_count {
		node := c.nodes[i]
		if node.level == level && node.low == low && node.high == high { return i + 2 }
	}
	if c.node_count >= max_zdd { return -1 }
	c.nodes[c.node_count] = ZNode{level, low, high}
	c.node_count++
	return c.node_count + 1
}

fn solve(mut c &Context, level int, mate [max_n]u8) int {
	if level == c.m { return 0 }
	cached := memo_find(c, level, mate)
	if cached >= 0 { return cached }
	mut next := [max_n]u8{}
	low_status := transition(c, level, mate, false, mut next)
	low := if low_status == 0 { 0 } else { solve(mut c, level + 1, next) }
	high_status := transition(c, level, mate, true, mut next)
	mut high := 0
	if high_status == 2 { high = 1 } else if high_status == 1 { high = solve(mut c, level + 1, next) }
	result := make_node(mut c, level, low, high)
	if result < 0 || c.memo_count >= max_states { return -1 }
	c.memo[c.memo_count] = Memo{level, mate, result}
	c.memo_count++
	return result
}

fn reachable_nodes(c &Context, root int) int {
	mut seen := [max_zdd + 2]bool{}
	mut stack := [2 * max_zdd + 3]int{}
	mut top := 1
	mut count := 0
	stack[0] = root
	for top > 0 {
		top--
		id := stack[top]
		if id <= 1 || seen[id] { continue }
		seen[id] = true
		count++
		node := c.nodes[id - 2]
		stack[top] = node.low
		top++
		stack[top] = node.high
		top++
	}
	return count
}

@[export: 'simpath_st_paths_zdd']
pub fn simpath_st_paths_zdd(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n64 := input[0]
		m64 := input[1]
		s64 := input[2]
		t64 := input[3]
		if n64 < 2 || n64 > max_n || m64 < 0 || m64 > max_m || s64 < 0 || s64 >= n64 || t64 < 0 || t64 >= n64 || s64 == t64 || i64(length) != 4 + 2 * m64 { return -1 }
		mut c := Context{n: int(n64), m: int(m64), source: int(s64), target: int(t64)}
		for v in 0 .. c.n { c.last[v] = -1 }
		for i in 0 .. c.m {
			u64 := input[4 + 2 * i]
			v64 := input[5 + 2 * i]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
			for j in 0 .. i { if c.edges[j].u == int(u64) && c.edges[j].v == int(v64) { return -1 } }
			u := int(u64)
			v := int(v64)
			c.edges[i] = Edge{u, v}
			c.last[u] = i
			c.last[v] = i
		}
		mut initial := [max_n]u8{}
		for v in 0 .. c.n { initial[v] = u8(v + 1) }
		root := solve(mut c, 0, initial)
		if root < 0 { return -1 }
		mut ways := [max_zdd + 2]u16{}
		ways[1] = 1
		for id in 2 .. c.node_count + 2 {
			node := c.nodes[id - 2]
			ways[id] = ways[node.low] + ways[node.high]
		}
		path_count := int(ways[root])
		if path_count >= int(radix) { return -1 }
		return i64(reachable_nodes(c, root)) * radix + i64(path_count)
	}
}
