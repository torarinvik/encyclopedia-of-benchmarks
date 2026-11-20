// Primal-dual weighted matching with odd-cycle contraction.
package general_weighted_matching_primal_dual_blossom

import "core:c"

MAX_N :: 64
SLOTS :: 2 * MAX_N + 1
INF :: i64(9223372036854775807)

Matcher :: struct {
	n, nodes, epoch: int,
	weight: [SLOTS][SLOTS]i64,
	dual: [SLOTS]i64,
	edge_a, edge_b: [SLOTS][SLOTS]i16,
	mate, slack_from, top, parent, state: [SLOTS]i16,
	seen: [SLOTS]int,
	members: [SLOTS][SLOTS]i16,
	member_count: [SLOTS]i16,
	child_of: [SLOTS][MAX_N + 1]i16,
	queue: [MAX_N]int,
	queued: [MAX_N]bool,
	head, tail, count: int,
}

delta :: proc(m: ^Matcher, a, b: int) -> i64 {
	return m.dual[int(m.edge_a[a][b])] + m.dual[int(m.edge_b[a][b])] - 2 * m.weight[a][b]
}

enqueue_leaf :: proc(m: ^Matcher, v: int) {
	if v <= 0 || v > m.n || m.queued[v - 1] do return
	m.queue[m.tail] = v
	m.tail = (m.tail + 1) % m.n
	m.count += 1
	m.queued[v - 1] = true
}

enqueue_members :: proc(m: ^Matcher, x: int) {
	if x <= m.n { enqueue_leaf(m, x); return }
	for i in 0..<int(m.member_count[x]) { enqueue_members(m, int(m.members[x][i])) }
}

set_top :: proc(m: ^Matcher, x, b: int) {
	m.top[x] = i16(b)
	if x > m.n {
		for i in 0..<int(m.member_count[x]) { set_top(m, int(m.members[x][i]), b) }
	}
}

update_slack :: proc(m: ^Matcher, u, x: int) {
	old := int(m.slack_from[x])
	if old == 0 || delta(m, u, x) < delta(m, old, x) do m.slack_from[x] = i16(u)
}

refresh_slack :: proc(m: ^Matcher, x: int) {
	m.slack_from[x] = 0
	for u in 1..=m.n {
		component := int(m.top[u])
		if m.weight[u][x] > 0 && component != x && m.state[component] == 0 do update_slack(m, u, x)
	}
}

cycle_position :: proc(m: ^Matcher, b, child: int) -> int {
	size := int(m.member_count[b])
	pos := 0
	for pos < size && int(m.members[b][pos]) != child { pos += 1 }
	if pos == size do return 0
	if pos % 2 == 1 {
		left, right := 1, size - 1
		for left < right {
			tmp := m.members[b][left]
			m.members[b][left] = m.members[b][right]
			m.members[b][right] = tmp
			left += 1
			right -= 1
		}
		pos = size - pos
	}
	return pos
}

rotate_cycle :: proc(m: ^Matcher, b, start: int) {
	size := int(m.member_count[b])
	saved: [SLOTS]i16
	for i in 0..<size { saved[i] = m.members[b][(i + start) % size] }
	for i in 0..<size { m.members[b][i] = saved[i] }
}

set_pair :: proc(m: ^Matcher, u, v: int) {
	m.mate[u] = m.edge_b[u][v]
	if u <= m.n do return
	leaf := int(m.edge_a[u][v])
	entry := int(m.child_of[u][leaf])
	pos := cycle_position(m, u, entry)
	for i in 0..<pos { set_pair(m, int(m.members[u][i]), int(m.members[u][i ^ 1])) }
	set_pair(m, entry, v)
	rotate_cycle(m, u, pos)
}

augment :: proc(m: ^Matcher, u_start, v_start: int) {
	u, v := u_start, v_start
	for {
		next := int(m.top[int(m.mate[u])])
		set_pair(m, u, v)
		if next == 0 do return
		prior := int(m.top[int(m.parent[next])])
		set_pair(m, next, prior)
		u, v = prior, next
	}
}

common_base :: proc(m: ^Matcher, u_start, v_start: int) -> int {
	m.epoch += 1
	u, v := u_start, v_start
	for u != 0 || v != 0 {
		if u != 0 {
			if m.seen[u] == m.epoch do return u
			m.seen[u] = m.epoch
			u = int(m.top[int(m.mate[u])])
			if u != 0 do u = int(m.top[int(m.parent[u])])
		}
		u, v = v, u
	}
	return 0
}

add_child :: proc(m: ^Matcher, b, x: int) {
	at := int(m.member_count[b])
	m.members[b][at] = i16(x)
	m.member_count[b] += 1
}

contract :: proc(m: ^Matcher, u, base, v: int) {
	b := m.n + 1
	for b <= m.nodes && m.top[b] != 0 { b += 1 }
	if b > m.nodes do m.nodes += 1
	m.dual[b] = 0
	m.state[b] = 0
	m.mate[b] = m.mate[base]
	m.member_count[b] = 0
	add_child(m, b, base)
	x := u
	for x != base {
		add_child(m, b, x)
		y := int(m.top[int(m.mate[x])])
		add_child(m, b, y)
		enqueue_members(m, y)
		x = int(m.top[int(m.parent[y])])
	}
	left, right := 1, int(m.member_count[b]) - 1
	for left < right {
		tmp := m.members[b][left]
		m.members[b][left] = m.members[b][right]
		m.members[b][right] = tmp
		left += 1
		right -= 1
	}
	x = v
	for x != base {
		add_child(m, b, x)
		y := int(m.top[int(m.mate[x])])
		add_child(m, b, y)
		enqueue_members(m, y)
		x = int(m.top[int(m.parent[y])])
	}
	set_top(m, b, b)
	for y in 1..=m.nodes {
		m.weight[b][y] = 0; m.weight[y][b] = 0
		m.edge_a[b][y] = 0; m.edge_b[b][y] = 0
		m.edge_a[y][b] = 0; m.edge_b[y][b] = 0
	}
	for leaf in 0..=MAX_N { m.child_of[b][leaf] = 0 }
	for i in 0..<int(m.member_count[b]) {
		child := int(m.members[b][i])
		for y in 1..=m.nodes {
			if m.weight[child][y] == 0 do continue
			if m.weight[b][y] == 0 || delta(m, child, y) < delta(m, b, y) {
				m.weight[b][y] = m.weight[child][y]
				m.edge_a[b][y] = m.edge_a[child][y]; m.edge_b[b][y] = m.edge_b[child][y]
				m.weight[y][b] = m.weight[y][child]
				m.edge_a[y][b] = m.edge_a[y][child]; m.edge_b[y][b] = m.edge_b[y][child]
			}
		}
		for leaf in 1..=m.n {
			contains := child <= m.n ? child == leaf : m.child_of[child][leaf] != 0
			if contains do m.child_of[b][leaf] = i16(child)
		}
	}
	refresh_slack(m, b)
}

expand_blossom :: proc(m: ^Matcher, b: int) {
	for i in 0..<int(m.member_count[b]) {
		child := int(m.members[b][i])
		set_top(m, child, child)
	}
	outside := int(m.parent[b])
	entry_leaf := int(m.edge_a[b][outside])
	entry := int(m.child_of[b][entry_leaf])
	pos := cycle_position(m, b, entry)
	i := 0
	for i < pos {
		inner := int(m.members[b][i]); outer := int(m.members[b][i + 1])
		m.parent[inner] = m.edge_a[outer][inner]
		m.state[inner] = 1; m.state[outer] = 0; m.slack_from[inner] = 0
		refresh_slack(m, outer); enqueue_members(m, outer)
		i += 2
	}
	m.state[entry] = 1
	m.parent[entry] = i16(outside)
	for i in pos + 1..<int(m.member_count[b]) {
		child := int(m.members[b][i])
		m.state[child] = -1
		refresh_slack(m, child)
	}
	m.top[b] = 0
}

process_edge :: proc(m: ^Matcher, left, right: int) -> bool {
	u := int(m.top[left]); v := int(m.top[right])
	if m.state[v] == -1 {
		m.parent[v] = i16(left); m.state[v] = 1
		next := int(m.top[int(m.mate[v])])
		m.slack_from[v] = 0; m.slack_from[next] = 0; m.state[next] = 0
		enqueue_members(m, next)
	} else if m.state[v] == 0 {
		base := common_base(m, u, v)
		if base == 0 { augment(m, u, v); augment(m, v, u); return true }
		contract(m, u, base, v)
	}
	return false
}

stage :: proc(m: ^Matcher) -> bool {
	for x in 0..=m.nodes { m.state[x] = -1; m.slack_from[x] = 0 }
	m.head, m.tail, m.count = 0, 0, 0
	for i in 0..=MAX_N { m.queued[i] = false }
	for x in 1..=m.nodes {
		if int(m.top[x]) == x && m.mate[x] == 0 {
			m.parent[x] = 0; m.state[x] = 0; enqueue_members(m, x)
		}
	}
	if m.count == 0 do return false
	for {
		for m.count != 0 {
			u := m.queue[m.head]; m.head = (m.head + 1) % m.n; m.count -= 1; m.queued[u - 1] = false
			if m.state[int(m.top[u])] == 1 do continue
			for v in 1..=m.n {
				if m.weight[u][v] == 0 || m.top[u] == m.top[v] do continue
				if delta(m, u, v) == 0 {
					if process_edge(m, int(m.edge_a[u][v]), int(m.edge_b[u][v])) do return true
				} else { update_slack(m, u, int(m.top[v])) }
			}
		}
		step := INF
		for u in 1..=m.n { if m.state[int(m.top[u])] == 0 do step = min(step, m.dual[u]) }
		for b in m.n + 1..=m.nodes { if int(m.top[b]) == b && m.state[b] == 1 do step = min(step, m.dual[b] / 2) }
		for x in 1..=m.nodes {
			if int(m.top[x]) != x || m.slack_from[x] == 0 do continue
			slack := delta(m, int(m.slack_from[x]), x)
			if m.state[x] == -1 { step = min(step, slack) }
			else if m.state[x] == 0 { step = min(step, slack / 2) }
		}
		if step == INF do return false
		for u in 1..=m.n {
			state := m.state[int(m.top[u])]
			if state == 0 { if m.dual[u] == step do return false; m.dual[u] -= step }
			else if state == 1 { m.dual[u] += step }
		}
		for b in m.n + 1..=m.nodes {
			if int(m.top[b]) != b do continue
			if m.state[b] == 0 { m.dual[b] += 2 * step }
			else if m.state[b] == 1 { m.dual[b] -= 2 * step }
		}
		for x in 1..=m.nodes {
			if int(m.top[x]) == x && m.slack_from[x] != 0 && int(m.top[int(m.slack_from[x])]) != x && delta(m, int(m.slack_from[x]), x) == 0 {
				source := int(m.slack_from[x])
				if process_edge(m, int(m.edge_a[source][x]), int(m.edge_b[source][x])) do return true
			}
		}
		for b in m.n + 1..=m.nodes { if int(m.top[b]) == b && m.state[b] == 1 && m.dual[b] == 0 do expand_blossom(m, b) }
	}
}

@(export)
general_weighted_matching_primal_dual_blossom :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 6051 do return -2
	nv, mv := input[0], input[1]
	if nv < 1 || nv > MAX_N || mv < 0 || mv > nv * (nv - 1) / 2 do return -2
	n, edges := int(nv), int(mv)
	if int(length) != 2 + 3 * edges do return -2
	search: Matcher
	search.n, search.nodes = n, n
	largest: i64 = 0
	for i in 0..<edges {
		uval, vval, wt := input[2 + 3*i], input[3 + 3*i], input[4 + 3*i]
		if uval < 0 || uval >= nv || vval < 0 || vval >= nv || uval == vval || wt < 1 || wt > 1_000_000 do return -2
		u, v := int(uval) + 1, int(vval) + 1
		if search.weight[u][v] != 0 do return -2
		search.weight[u][v], search.weight[v][u] = wt, wt
		search.edge_a[u][v], search.edge_b[u][v] = i16(u), i16(v)
		search.edge_a[v][u], search.edge_b[v][u] = i16(v), i16(u)
		largest = max(largest, wt)
	}
	for u in 1..=n { search.top[u] = i16(u); search.dual[u] = largest; search.child_of[u][u] = i16(u) }
	for stage(&search) {}
	answer: i64 = 0
	for u in 1..=n { v := int(search.mate[u]); if v > u do answer += search.weight[u][v] }
	return answer
}
