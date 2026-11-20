// Maximum-weight matching by primal-dual blossom contraction.
const max_n = 64
const slots = 129
const infinity = i64(9223372036854775807)

struct Matcher {
mut:
	n int
	nodes int
	epoch int
	weight [slots][slots]i64
	dual [slots]i64
	edge_a [slots][slots]i16
	edge_b [slots][slots]i16
	mate [slots]i16
	slack_from [slots]i16
	top [slots]i16
	parent [slots]i16
	state [slots]i16
	seen [slots]int
	members [slots][slots]i16
	member_count [slots]i16
	child_of [slots][max_n + 1]i16
	queue [max_n]int
	queued [max_n + 1]bool
	head int
	tail int
	count int
}

fn (m &Matcher) delta(a int, b int) i64 {
	return m.dual[m.edge_a[a][b]] + m.dual[m.edge_b[a][b]] - 2 * m.weight[a][b]
}

fn (mut m Matcher) enqueue_leaf(v int) {
	if v <= 0 || v > m.n || m.queued[v] { return }
	m.queue[m.tail] = v
	m.tail = (m.tail + 1) % m.n
	m.count++
	m.queued[v] = true
}

fn (mut m Matcher) enqueue_members(x int) {
	if x <= m.n { m.enqueue_leaf(x); return }
	for i in 0 .. int(m.member_count[x]) { m.enqueue_members(int(m.members[x][i])) }
}

fn (mut m Matcher) set_top(x int, b int) {
	m.top[x] = i16(b)
	if x > m.n {
		for i in 0 .. int(m.member_count[x]) { m.set_top(int(m.members[x][i]), b) }
	}
}

fn (mut m Matcher) update_slack(u int, x int) {
	old := int(m.slack_from[x])
	if old == 0 || m.delta(u, x) < m.delta(old, x) { m.slack_from[x] = i16(u) }
}

fn (mut m Matcher) refresh_slack(x int) {
	m.slack_from[x] = 0
	for u in 1 .. m.n + 1 {
		component := int(m.top[u])
		if m.weight[u][x] > 0 && component != x && m.state[component] == 0 { m.update_slack(u, x) }
	}
}

fn (mut m Matcher) cycle_position(b int, child int) int {
	size := int(m.member_count[b])
	mut pos := 0
	for pos < size && int(m.members[b][pos]) != child { pos++ }
	if pos == size { return 0 }
	if pos % 2 == 1 {
		mut left := 1
		mut right := size - 1
		for left < right {
			tmp := m.members[b][left]
			m.members[b][left] = m.members[b][right]
			m.members[b][right] = tmp
			left++
			right--
		}
		pos = size - pos
	}
	return pos
}

fn (mut m Matcher) rotate_cycle(b int, start int) {
	size := int(m.member_count[b])
	mut saved := [slots]i16{}
	for i in 0 .. size { saved[i] = m.members[b][(i + start) % size] }
	for i in 0 .. size { m.members[b][i] = saved[i] }
}

fn (mut m Matcher) set_pair(u int, v int) {
	m.mate[u] = m.edge_b[u][v]
	if u <= m.n { return }
	leaf := int(m.edge_a[u][v])
	entry := int(m.child_of[u][leaf])
	pos := m.cycle_position(u, entry)
	for i in 0 .. pos { m.set_pair(int(m.members[u][i]), int(m.members[u][i ^ 1])) }
	m.set_pair(entry, v)
	m.rotate_cycle(u, pos)
}

fn (mut m Matcher) augment(u_start int, v_start int) {
	mut u := u_start
	mut v := v_start
	for {
		next := int(m.top[m.mate[u]])
		m.set_pair(u, v)
		if next == 0 { return }
		prior := int(m.top[m.parent[next]])
		m.set_pair(next, prior)
		u = prior
		v = next
	}
}

fn (mut m Matcher) common_base(u_start int, v_start int) int {
	m.epoch++
	mut u := u_start
	mut v := v_start
	for u != 0 || v != 0 {
		if u != 0 {
			if m.seen[u] == m.epoch { return u }
			m.seen[u] = m.epoch
			u = int(m.top[m.mate[u]])
			if u != 0 { u = int(m.top[m.parent[u]]) }
		}
		tmp := u
		u = v
		v = tmp
	}
	return 0
}

fn (mut m Matcher) add_child(b int, x int) {
	at := int(m.member_count[b])
	m.members[b][at] = i16(x)
	m.member_count[b]++
}

fn (mut m Matcher) contract(u int, base int, v int) {
	mut b := m.n + 1
	for b <= m.nodes && m.top[b] != 0 { b++ }
	if b > m.nodes { m.nodes++ }
	m.dual[b] = 0
	m.state[b] = 0
	m.mate[b] = m.mate[base]
	m.member_count[b] = 0
	m.add_child(b, base)
	mut x := u
	for x != base {
		m.add_child(b, x)
		y := int(m.top[m.mate[x]])
		m.add_child(b, y)
		m.enqueue_members(y)
		x = int(m.top[m.parent[y]])
	}
	mut left := 1
	mut right := int(m.member_count[b]) - 1
	for left < right {
		tmp := m.members[b][left]
		m.members[b][left] = m.members[b][right]
		m.members[b][right] = tmp
		left++
		right--
	}
	x = v
	for x != base {
		m.add_child(b, x)
		y := int(m.top[m.mate[x]])
		m.add_child(b, y)
		m.enqueue_members(y)
		x = int(m.top[m.parent[y]])
	}
	m.set_top(b, b)
	for y in 1 .. m.nodes + 1 {
		m.weight[b][y] = 0
		m.weight[y][b] = 0
		m.edge_a[b][y] = 0
		m.edge_b[b][y] = 0
		m.edge_a[y][b] = 0
		m.edge_b[y][b] = 0
	}
	for leaf in 0 .. max_n + 1 { m.child_of[b][leaf] = 0 }
	for i in 0 .. int(m.member_count[b]) {
		child := int(m.members[b][i])
		for y in 1 .. m.nodes + 1 {
			if m.weight[child][y] == 0 { continue }
			if m.weight[b][y] == 0 || m.delta(child, y) < m.delta(b, y) {
				m.weight[b][y] = m.weight[child][y]
				m.edge_a[b][y] = m.edge_a[child][y]
				m.edge_b[b][y] = m.edge_b[child][y]
				m.weight[y][b] = m.weight[y][child]
				m.edge_a[y][b] = m.edge_a[y][child]
				m.edge_b[y][b] = m.edge_b[y][child]
			}
		}
		for leaf in 1 .. m.n + 1 {
			contains := if child <= m.n { child == leaf } else { m.child_of[child][leaf] != 0 }
			if contains { m.child_of[b][leaf] = i16(child) }
		}
	}
	m.refresh_slack(b)
}

fn (mut m Matcher) expand_blossom(b int) {
	for i in 0 .. int(m.member_count[b]) {
		child := int(m.members[b][i])
		m.set_top(child, child)
	}
	outside := int(m.parent[b])
	entry_leaf := int(m.edge_a[b][outside])
	entry := int(m.child_of[b][entry_leaf])
	pos := m.cycle_position(b, entry)
	mut i := 0
	for i < pos {
		inner := int(m.members[b][i])
		outer := int(m.members[b][i + 1])
		m.parent[inner] = m.edge_a[outer][inner]
		m.state[inner] = 1
		m.state[outer] = 0
		m.slack_from[inner] = 0
		m.refresh_slack(outer)
		m.enqueue_members(outer)
		i += 2
	}
	m.state[entry] = 1
	m.parent[entry] = i16(outside)
	for i in pos + 1 .. int(m.member_count[b]) {
		child := int(m.members[b][i])
		m.state[child] = -1
		m.refresh_slack(child)
	}
	m.top[b] = 0
}

fn (mut m Matcher) process_edge(left int, right int) bool {
	u := int(m.top[left])
	v := int(m.top[right])
	if m.state[v] == -1 {
		m.parent[v] = i16(left)
		m.state[v] = 1
		next := int(m.top[m.mate[v]])
		m.slack_from[v] = 0
		m.slack_from[next] = 0
		m.state[next] = 0
		m.enqueue_members(next)
	} else if m.state[v] == 0 {
		base := m.common_base(u, v)
		if base == 0 {
			m.augment(u, v)
			m.augment(v, u)
			return true
		}
		m.contract(u, base, v)
	}
	return false
}

fn (mut m Matcher) stage() bool {
	for x in 0 .. m.nodes + 1 { m.state[x] = -1; m.slack_from[x] = 0 }
	m.head = 0
	m.tail = 0
	m.count = 0
	for i in 0 .. max_n + 1 { m.queued[i] = false }
	for x in 1 .. m.nodes + 1 {
		if int(m.top[x]) == x && m.mate[x] == 0 {
			m.parent[x] = 0
			m.state[x] = 0
			m.enqueue_members(x)
		}
	}
	if m.count == 0 { return false }
	for {
		for m.count != 0 {
			u := m.queue[m.head]
			m.head = (m.head + 1) % m.n
			m.count--
			m.queued[u] = false
			if m.state[m.top[u]] == 1 { continue }
			for v in 1 .. m.n + 1 {
				if m.weight[u][v] == 0 || m.top[u] == m.top[v] { continue }
				if m.delta(u, v) == 0 {
					if m.process_edge(int(m.edge_a[u][v]), int(m.edge_b[u][v])) { return true }
				} else {
					m.update_slack(u, m.top[v])
				}
			}
		}
		mut step := infinity
		for u in 1 .. m.n + 1 { if m.state[m.top[u]] == 0 && m.dual[u] < step { step = m.dual[u] } }
		for b in m.n + 1 .. m.nodes + 1 { if m.top[b] == b && m.state[b] == 1 && m.dual[b] / 2 < step { step = m.dual[b] / 2 } }
		for x in 1 .. m.nodes + 1 {
			if m.top[x] != x || m.slack_from[x] == 0 { continue }
			slack := m.delta(m.slack_from[x], x)
			if m.state[x] == -1 && slack < step { step = slack }
			else if m.state[x] == 0 && slack / 2 < step { step = slack / 2 }
		}
		if step == infinity { return false }
		for u in 1 .. m.n + 1 {
			state := m.state[m.top[u]]
			if state == 0 {
				if m.dual[u] == step { return false }
				m.dual[u] -= step
			} else if state == 1 { m.dual[u] += step }
		}
		for b in m.n + 1 .. m.nodes + 1 {
			if m.top[b] != b { continue }
			if m.state[b] == 0 { m.dual[b] += 2 * step }
			else if m.state[b] == 1 { m.dual[b] -= 2 * step }
		}
		for x in 1 .. m.nodes + 1 {
			if m.top[x] == x && m.slack_from[x] != 0 && m.top[m.slack_from[x]] != x && m.delta(m.slack_from[x], x) == 0 {
				source := m.slack_from[x]
				if m.process_edge(int(m.edge_a[source][x]), int(m.edge_b[source][x])) { return true }
			}
		}
		for b in m.n + 1 .. m.nodes + 1 { if m.top[b] == b && m.state[b] == 1 && m.dual[b] == 0 { m.expand_blossom(b) } }
	}
}

@[export: 'general_weighted_matching_primal_dual_blossom']
pub fn general_weighted_matching_primal_dual_blossom(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 6051 { return -2 }
		nv, mv := input[0], input[1]
		if nv < 1 || nv > max_n || mv < 0 || mv > nv * (nv - 1) / 2 { return -2 }
		n, edges := int(nv), int(mv)
		if length != usize(2 + 3 * edges) { return -2 }
		mut search := Matcher{}
		search.n = n
		search.nodes = n
		mut largest := i64(0)
		for i in 0 .. edges {
			uval, vval, weight := input[2 + 3 * i], input[3 + 3 * i], input[4 + 3 * i]
			if uval < 0 || uval >= nv || vval < 0 || vval >= nv || uval == vval || weight < 1 || weight > 1000000 { return -2 }
			u, v := int(uval) + 1, int(vval) + 1
			if search.weight[u][v] != 0 { return -2 }
			search.weight[u][v] = weight
			search.weight[v][u] = weight
			search.edge_a[u][v] = i16(u); search.edge_b[u][v] = i16(v)
			search.edge_a[v][u] = i16(v); search.edge_b[v][u] = i16(u)
			if weight > largest { largest = weight }
		}
		for u in 1 .. n + 1 {
			search.top[u] = i16(u)
			search.dual[u] = largest
			search.child_of[u][u] = i16(u)
		}
		for search.stage() {}
		mut answer := i64(0)
		for u in 1 .. n + 1 {
			v := int(search.mate[u])
			if v > u { answer += search.weight[u][v] }
		}
		return answer
	}
}
