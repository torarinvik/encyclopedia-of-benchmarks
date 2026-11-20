module khuller_raghavachari_three_edge_connected_spanning_subgraph
import core.c

const max_n = 8
const max_m = 28
const max_input = 59

fn put(out &u8, at int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { out[at + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'khuller_raghavachari_three_edge_connected_spanning_subgraph']
pub fn khuller_raghavachari_three_edge_connected_spanning_subgraph(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 4 || n64 > 8 || m64 < 6 || m64 > 28 || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut u := []int{len: max_m, init: 0}
		mut v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			a, b := input[2 + 2 * edge], input[3 + 2 * edge]
			if a < 0 || a >= b || b >= n64 { return -1 }
			u[edge], v[edge] = int(a), int(b)
			for prior in 0 .. edge { if u[prior] == u[edge] && v[prior] == v[edge] { return -1 } }
		}
		full := (1 << n) - 1
		for side in 1 .. full {
			if (side & 1) == 0 { continue }
			mut cut := 0
			for edge in 0 .. m {
				if ((side >> u[edge]) & 1) != ((side >> v[edge]) & 1) { cut++ }
			}
			if cut < 3 { return -1 }
		}

		mut selected := []bool{len: max_m, init: false}
		mut state := []int{len: max_n, init: 0}
		mut discovery := []int{len: max_n, init: 0}
		mut finish := []int{len: max_n, init: 0}
		mut parent := []int{len: max_n, init: 0}
		mut parent_edge := []int{len: max_n, init: 0}
		mut postorder := []int{len: max_n, init: 0}
		mut stack_vertex := []int{len: max_n, init: 0}
		mut stack_slot := []int{len: max_n, init: 0}
		mut post_count := 0
		mut clock := 1
		mut top := 1
		state[0] = 1
		discovery[0] = 0
		parent[0] = n
		parent_edge[0] = m
		stack_vertex[0] = 0
		for top > 0 {
			frame := top - 1
			x := stack_vertex[frame]
			if stack_slot[frame] < m {
				edge := stack_slot[frame]
				stack_slot[frame]++
				y := n
				if u[edge] == x { y = v[edge] } else if v[edge] == x { y = u[edge] }
				if y == n || state[y] != 0 { continue }
				selected[edge] = true
				state[y] = 1
				parent[y] = x
				parent_edge[y] = edge
				discovery[y] = clock
				clock++
				stack_vertex[top] = y
				stack_slot[top] = 0
				top++
				continue
			}
			state[x] = 2
			finish[x] = clock
			if parent_edge[x] < m { postorder[post_count] = parent_edge[x]; post_count++ }
			top--
		}

		for position in 0 .. post_count {
			tree_edge := postorder[position]
			child := v[tree_edge]
			if parent_edge[u[tree_edge]] == tree_edge { child = u[tree_edge] }
			upper := parent[child]
			mut separated := false
			for removed in 0 .. m {
				if separated || !selected[removed] { continue }
				mut seen := []bool{len: max_n, init: false}
				mut queue := []int{len: max_n, init: 0}
				mut head := 0
				mut tail := 1
				seen[upper] = true
				queue[0] = upper
				for head < tail {
					current := queue[head]
					head++
					for edge in 0 .. m {
						if !selected[edge] || edge == removed { continue }
						next := n
						if u[edge] == current { next = v[edge] } else if v[edge] == current { next = u[edge] }
						if next < n && !seen[next] {
							seen[next] = true
							queue[tail] = next
							tail++
						}
					}
				}
				if !seen[child] { separated = true }
			}
			if !separated { continue }
			mut candidate := m
			mut earliest := n
			for edge in 0 .. m {
				if selected[edge] { continue }
				u_inside := discovery[child] <= discovery[u[edge]] && discovery[u[edge]] < finish[child]
				v_inside := discovery[child] <= discovery[v[edge]] && discovery[v[edge]] < finish[child]
				if u_inside == v_inside { continue }
				ancestor := u[edge]
				if u_inside { ancestor = v[edge] }
				if discovery[ancestor] < earliest { earliest = discovery[ancestor]; candidate = edge }
			}
			if candidate == m { return -1 }
			selected[candidate] = true
		}

		mut leader := []int{len: max_n, init: 0}
		for vertex in 0 .. n { leader[vertex] = vertex }
		for edge in 0 .. m {
			if selected[edge] { continue }
			mut a, b := u[edge], v[edge]
			for leader[a] != a { leader[a] = leader[leader[a]]; a = leader[a] }
			for leader[b] != b { leader[b] = leader[leader[b]]; b = leader[b] }
			if a != b { leader[b] = a; selected[edge] = true }
		}
		mut count := 0
		for edge in 0 .. m { if selected[edge] { count++ } }
		bytes := 8 * (1 + 2 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put(output, 0, i64(count))
		mut slot := 0
		for edge in 0 .. m {
			if !selected[edge] { continue }
			put(output, 8 * (1 + 2 * slot), i64(u[edge]))
			put(output, 8 * (2 + 2 * slot), i64(v[edge]))
			slot++
		}
		return i64(bytes)
	}
}
