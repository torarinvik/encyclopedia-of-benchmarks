module two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs
import core.c

const max_n = 8
const max_m = 28
const max_input = 59

fn put(out &u8, at int, value i64) {
	bits := u64(value)
	for i in 0 .. 8 { out[at + i] = u8((bits >> (8 * i)) & 255) }
}
fn connected_without_vertex(n, m int, u, v []int, removed int) bool {
	mut seen := []bool{len: max_n, init: false}
	mut queue := []int{len: max_n, init: 0}
	mut head := 0
	mut tail := 1
	start := if removed == 0 { 1 } else { 0 }
	queue[0] = start
	seen[start] = true
	for head < tail {
		x := queue[head]
		head++
		for e in 0 .. m {
			if u[e] == removed || v[e] == removed { continue }
			mut y := max_n
			if u[e] == x { y = v[e] } else if v[e] == x { y = u[e] }
			if y < n && !seen[y] { seen[y] = true; queue[tail] = y; tail++ }
		}
	}
	for i in 0 .. n { if i != removed && !seen[i] { return false } }
	return true
}

@[export: 'two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs']
pub fn two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28 || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut u := []int{len: max_m, init: 0}
		mut v := []int{len: max_m, init: 0}
		for e in 0 .. m {
			a, b := input[2 + 2 * e], input[3 + 2 * e]
			if a < 0 || a >= b || b >= n64 { return -1 }
			u[e], v[e] = int(a), int(b)
			for j in 0 .. e { if u[j] == u[e] && v[j] == v[e] { return -1 } }
		}
		for removed in 0 .. n { if !connected_without_vertex(n, m, u, v, removed) { return -1 } }

		mut state := []int{len: max_n, init: 0}
		mut disc := []int{len: max_n, init: 0}
		mut low := []int{len: max_n, init: 0}
		mut low_h := []int{len: max_n, init: 0}
		mut savior := []int{len: max_n, init: 0}
		mut selected := []bool{len: max_m, init: false}
		mut parent_edge := []int{len: max_n, init: 0}
		mut stack_v := []int{len: max_n, init: 0}
		mut stack_parent := []int{len: max_n, init: 0}
		mut stack_cursor := []int{len: max_n, init: 0}
		mut tick := 1
		mut top := 1
		state[0] = 1
		disc[0], low[0], low_h[0], savior[0] = 0, 0, 0, 0
		stack_v[0], stack_parent[0], stack_cursor[0] = 0, max_n, 0
		for top > 0 {
			frame := top - 1
			x, parent := stack_v[frame], stack_parent[frame]
			if stack_cursor[frame] < m {
				e := stack_cursor[frame]
				stack_cursor[frame]++
				mut y := max_n
				if u[e] == x { y = v[e] } else if v[e] == x { y = u[e] }
				if y == max_n { continue }
				if state[y] == 0 {
					selected[e] = true
				parent_edge[y] = e
					state[y] = 1
					disc[y] = tick
					tick++
					low[y], low_h[y], savior[y] = y, y, y
					stack_v[top], stack_parent[top], stack_cursor[top] = y, x, 0
					top++
				} else if state[y] == 1 && y != parent && disc[y] < disc[low[x]] {
					low[x], savior[x] = y, x
				}
				continue
			}
			state[x] = 2
			if parent < n && low_h[x] == x {
				lo, hi := min(savior[x], low[x]), max(savior[x], low[x])
				for e in 0 .. m {
					if u[e] == lo && v[e] == hi { selected[e] = true; break }
				}
				low_h[x] = low[x]
			}
			if parent < n && low_h[x] == parent {
				lo, hi := min(savior[x], low[x]), max(savior[x], low[x])
				for e in 0 .. m { if u[e] == lo && v[e] == hi { selected[e] = true; break } }
				low_h[x] = low[x]
				if savior[x] == x { selected[parent_edge[x]] = false }
			}
			top--
			if parent < n {
				if disc[low[x]] < disc[low[parent]] { low[parent], savior[parent] = low[x], savior[x] }
				if disc[low_h[x]] < disc[low_h[parent]] { low_h[parent] = low_h[x] }
			}
		}
		mut count := 0
		for e in 0 .. m { if selected[e] { count++ } }
		bytes := 8 * (1 + 2 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put(output, 0, i64(count))
		mut at := 8
		for a in 0 .. n { for b in a + 1 .. n { for e in 0 .. m {
			if selected[e] && u[e] == a && v[e] == b { put(output, at, i64(a)); put(output, at + 8, i64(b)); at += 16 }
		} } }
		return i64(bytes)
	}
}
