module minimal_dominating_sets_permutation_graphs

const max_n = 8
const max_parseable_length = usize(10)
const max_states = 59049

struct Context {
mut:
	n int
	top [max_n]int
	top_vertex [max_n]int
	adj [max_n][max_n]bool
	ways [max_states]i64
}

struct Successor {
	valid bool
	r int
	s int
}

fn graph_case(c &Context, i int, j int, k int) int {
	a, b, d := c.top[i], c.top[j], c.top[k]
	if a < b && b < d { return 1 }
	if a < d && d < b { return 2 }
	if b < a && a < d { return 3 }
	if b < d && d < a { return 4 }
	if d < a && a < b { return 5 }
	return 0
}

fn covered(c &Context, y int, selected [5]int, count int) bool {
	for z in 0 .. count {
		if c.adj[selected[z]][y] { return true }
	}
	return false
}

fn irredundant(c &Context, selected [5]int, count int) bool {
	for x in 0 .. count {
		mut found := false
		for y in 0 .. c.n {
			if !c.adj[selected[x]][y] { continue }
			mut shared := false
			for z in 0 .. count {
				if z != x && c.adj[selected[z]][y] { shared = true; break }
			}
			if !shared { found = true; break }
		}
		if !found { return false }
	}
	return true
}

fn private_min_rank(c &Context, x int, selected [5]int, count int) int {
	mut best := -1
	for y in 0 .. c.n {
		if !c.adj[x][y] { continue }
		mut shared := false
		for z in 0 .. count {
			if selected[z] != x && c.adj[selected[z]][y] { shared = true; break }
		}
		if !shared && (best < 0 || c.top[y] < c.top[best]) { best = y }
	}
	return best
}

fn is_initial(c &Context, i int, j int, k int, r int, s int) bool {
	tri := [5]int{i, j, k, 0, 0}
	if r != c.n || !irredundant(c, tri, 3) { return false }
	kind := graph_case(c, i, j, k)
	if kind == 1 {
		for y in 0 .. c.n { if y < i && c.top[y] < c.top[i] { return false } }
		return s == private_min_rank(c, i, tri, 3)
	}
	if kind == 2 {
		if s != c.n { return false }
		for y in 0 .. c.n { if c.top[y] < c.top[k] && y < j && !covered(c, y, tri, 3) { return false } }
		return true
	}
	if kind == 3 {
		for y in 0 .. c.n { if c.top[y] < c.top[j] && y < i { return false } }
		return s == private_min_rank(c, j, tri, 3)
	}
	if kind == 4 {
		if s != c.n { return false }
		for y in 0 .. c.n { if c.top[y] < c.top[j] && y < i && !covered(c, y, tri, 3) { return false } }
		return true
	}
	if kind == 5 {
		for y in 0 .. c.n { if c.top[y] < c.top[k] && y < i { return false } }
		return s == private_min_rank(c, k, tri, 3)
	}
	return false
}

fn is_regular(c &Context, i int, j int, k int, r int, s int) bool {
	tri := [5]int{i, j, k, 0, 0}
	if !irredundant(c, tri, 3) { return false }
	kind := graph_case(c, i, j, k)
	if kind >= 1 && kind <= 4 { if r < 0 || r >= i { return false } }
	else if kind == 5 { if r != c.n { return false } }
	else { return false }
	if kind == 2 || kind == 4 { return s == c.n }
	if s < 0 || s >= c.n { return false }
	if kind == 1 { return c.adj[i][s] && !c.adj[r][s] && !c.adj[j][s] && !c.adj[k][s] }
	if kind == 3 { return c.adj[j][s] && !c.adj[r][s] && !c.adj[i][s] && !c.adj[k][s] }
	return c.adj[k][s] && !c.adj[i][s] && !c.adj[j][s]
}

fn is_final(c &Context, i int, j int, k int, r int) bool {
	mut selected := [5]int{i, j, k, 0, 0}
	mut count := 3
	if r != c.n { selected = [5]int{r, i, j, k, 0}; count = 4 }
	for y in 0 .. c.n { if i < y && c.top[i] < c.top[y] && !covered(c, y, selected, count) { return false } }
	return true
}

fn state_index(i int, j int, k int, r int, s int, base int) int {
	return ((((i * base + j) * base + k) * base + r) * base + s)
}


fn successor(c &Context, i int, j int, k int, r int, s int, ell int) Successor {
	kind := graph_case(c, j, k, ell)
	if kind == 0 { return Successor{} }
	mut selected := [5]int{i, j, k, ell, 0}
	mut count := 4
	if r != c.n { selected = [5]int{r, i, j, k, ell}; count = 5 }
	if !irredundant(c, selected, count) || (s != c.n && c.top[ell] <= c.top[s]) { return Successor{} }
	if !c.adj[j][k] {
		for y in 0 .. c.n { if i < y && y < j && c.top[i] < c.top[y] && c.top[y] < c.top[j] && !covered(c, y, selected, count) { return Successor{} } }
	}
	if c.adj[i][k] {
		for y in 0 .. c.n { if j < y && y < k && c.top[j] < c.top[y] && c.top[y] < c.top[ell] && !covered(c, y, selected, count) { return Successor{} } }
	}
	mut out_r := c.n
	mut out_s := c.n
	if kind == 5 { out_r = c.n }
	else {
		mut highest := c.top[i]
		if r != c.n && c.top[r] > highest { highest = c.top[r] }
		out_r = c.top_vertex[highest]
	}
	if kind == 2 || kind == 4 { out_s = c.n }
	else {
		mut old_min := c.top[i]
		if c.top[j] < old_min { old_min = c.top[j] }
		if c.top[k] < old_min { old_min = c.top[k] }
		mut next_min := c.top[j]
		if c.top[k] < next_min { next_min = c.top[k] }
		if c.top[ell] < next_min { next_min = c.top[ell] }
		if s != c.n && old_min == next_min { out_s = s }
		else {
			mut y := j
			if c.top[k] < c.top[y] { y = k }
			if c.top[ell] < c.top[y] { y = ell }
			out_s = private_min_rank(c, y, selected, count)
			if out_s < 0 { return Successor{} }
		}
	}
	return Successor{valid: is_regular(c, j, k, ell, out_r, out_s), r: out_r, s: out_s}
}

fn dominates(mask u32, hoods [max_n]u32, n int) bool {
	mut cover := u32(0)
	for x in 0 .. n { if mask & (u32(1) << x) != 0 { cover |= hoods[x] } }
	return cover == (u32(1) << n) - 1
}

@[export: 'minimal_dominating_sets_permutation_graphs']
pub fn minimal_dominating_sets_permutation_graphs(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		mut c := Context{n: n}
		mut seen := [max_n]bool{}
		for x in 0 .. n {
			rank := input[x + 1]
			if rank < 0 || rank >= i64(n) { return -1 }
			ri := int(rank)
			if seen[ri] { return -1 }
			seen[ri] = true
			c.top[x] = ri
			c.top_vertex[ri] = x
			c.adj[x][x] = true
		}
		for x in 0 .. n { for y in x + 1 .. n {
			c.adj[x][y] = c.top[x] > c.top[y]
			c.adj[y][x] = c.adj[x][y]
		} }
		mut answer := i64(0)
		if n >= 3 {
			for i := n - 3; i >= 0; i-- {
				for j in i + 1 .. n - 1 { for k in j + 1 .. n {
					tri := [5]int{i, j, k, 0, 0}
					if graph_case(&c, i, j, k) == 0 || !irredundant(&c, tri, 3) { continue }
					for ri in 0 .. i + 1 {
						r := ri
						if ri == i { r = n }
						for s in 0 .. n + 1 {
							if !is_initial(&c, i, j, k, r, s) && !is_regular(&c, i, j, k, r, s) { continue }
							mut paths := i64(0)
							if is_final(&c, i, j, k, r) { paths = 1 }
							for ell in k + 1 .. n {
							step := successor(&c, i, j, k, r, s, ell)
							if step.valid { paths += c.ways[state_index(j, k, ell, step.r, step.s, n + 1)] }
							}
							c.ways[state_index(i, j, k, r, s, n + 1)] = paths
							if is_initial(&c, i, j, k, r, s) { answer += paths }
						}
					}
				} }
			}
		}
		mut hoods := [max_n]u32{}
		for x in 0 .. n { for y in 0 .. n { if c.adj[x][y] { hoods[x] |= u32(1) << y } } }
		full := (u32(1) << n) - 1
		for mask := u32(1); mask <= full; mask++ {
			mut size := 0
			mut bits := mask
			for bits != 0 { size += int(bits & 1); bits >>= 1 }
			if size > 2 || !dominates(mask, hoods, n) { continue }
			mut minimal := true
			for x in 0 .. n { if mask & (u32(1) << x) != 0 && dominates(mask ^ (u32(1) << x), hoods, n) { minimal = false } }
			if minimal { answer++ }
		}
		return answer
	}
}
