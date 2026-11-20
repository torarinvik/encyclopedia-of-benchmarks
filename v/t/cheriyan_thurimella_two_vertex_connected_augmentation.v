module cheriyan_thurimella_two_vertex_connected_augmentation
import core.c

const max_n = 8
const max_m = 28
const max_input = 59

fn put(out &u8, at int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { out[at + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn biconnected(n int, m int, u []int, v []int, active []bool) bool {
	for removed in 0 .. n {
		start := if removed == 0 { 1 } else { 0 }
		mut seen := []bool{len: max_n, init: false}
		mut queue := []int{len: max_n, init: 0}
		mut head := 0
		mut tail := 1
		seen[start] = true
		queue[0] = start
		for head < tail {
			current := queue[head]
			head++
			for edge in 0 .. m {
				if !active[edge] || u[edge] == removed || v[edge] == removed { continue }
				next := n
				if u[edge] == current { next = v[edge] } else if v[edge] == current { next = u[edge] }
				if next < n && !seen[next] {
					seen[next] = true
					queue[tail] = next
					tail++
				}
			}
		}
		for vertex in 0 .. n { if vertex != removed && !seen[vertex] { return false } }
	}
	return true
}

@[export: 'cheriyan_thurimella_two_vertex_connected_augmentation']
pub fn cheriyan_thurimella_two_vertex_connected_augmentation(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28 || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut u := []int{len: max_m, init: 0}
		mut v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			a, b := input[2 + 2 * edge], input[3 + 2 * edge]
			if a < 0 || a >= b || b >= n64 { return -1 }
			u[edge], v[edge] = int(a), int(b)
			for prior in 0 .. edge { if u[prior] == u[edge] && v[prior] == v[edge] { return -1 } }
		}
		mut active := []bool{len: max_m, init: false}
		for edge in 0 .. m { active[edge] = true }
		if !biconnected(n, m, u, v, active) { return -1 }

		states := 1 << n
		mut best := []int{len: states, init: 0}
		mut choice := []int{len: states, init: -1}
		for mask in 1 .. states {
			mut first := 0
			for (mask & (1 << first)) == 0 { first++ }
			for edge in 0 .. m {
				mut other := n
				if u[edge] == first { other = v[edge] } else if v[edge] == first { other = u[edge] }
				if other == n || (mask & (1 << other)) == 0 { continue }
				rest := mask & ~(1 << first) & ~(1 << other)
				candidate := 1 + best[rest]
				if candidate > best[mask] { best[mask] = candidate; choice[mask] = edge }
			}
			rest := mask & ~(1 << first)
			if best[rest] > best[mask] { best[mask] = best[rest]; choice[mask] = -1 }
		}
		mut cover := []bool{len: max_m, init: false}
		mut covered := []bool{len: max_n, init: false}
		mut mask := states - 1
		for mask != 0 {
			mut first := 0
			for (mask & (1 << first)) == 0 { first++ }
			edge := choice[mask]
			if edge < 0 { mask &= ~(1 << first); continue }
			cover[edge] = true
			covered[u[edge]], covered[v[edge]] = true, true
			mask &= ~(1 << u[edge]) & ~(1 << v[edge])
		}
		for vertex in 0 .. n {
			if covered[vertex] { continue }
			for edge in 0 .. m {
				if u[edge] == vertex || v[edge] == vertex {
					cover[edge] = true
					covered[u[edge]], covered[v[edge]] = true, true
					break
				}
			}
		}
		for edge in 0 .. m {
			if cover[edge] { continue }
			active[edge] = false
			if !biconnected(n, m, u, v, active) { active[edge] = true }
		}
		mut count := 0
		for edge in 0 .. m { if active[edge] { count++ } }
		bytes := 8 * (1 + 2 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put(output, 0, i64(count))
		mut slot := 0
		for edge in 0 .. m {
			if !active[edge] { continue }
			put(output, 8 * (1 + 2 * slot), i64(u[edge]))
			put(output, 8 * (2 + 2 * slot), i64(v[edge]))
			slot++
		}
		return i64(bytes)
	}
}
