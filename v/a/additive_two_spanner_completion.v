module additive_two_spanner_completion
import core.c

const max_n = 8
const max_m = 28
const max_input = 59
const inf = 9

fn put(out &u8, at int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { out[at + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn distances(n int, m int, u []int, v []int, selected []bool, only_selected bool) []int {
	mut d := []int{len: max_n * max_n, init: inf}
	for left in 0 .. n { d[left * max_n + left] = 0 }
	for edge in 0 .. m {
		if only_selected && !selected[edge] { continue }
		d[u[edge] * max_n + v[edge]] = 1
		d[v[edge] * max_n + u[edge]] = 1
	}
	for via in 0 .. n {
		for left in 0 .. n {
			for right in 0 .. n {
				candidate := d[left * max_n + via] + d[via * max_n + right]
				if candidate < d[left * max_n + right] { d[left * max_n + right] = candidate }
			}
		}
	}
	return d
}

@[export: 'additive_two_spanner_completion']
pub fn additive_two_spanner_completion(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 28 || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut u := []int{len: max_m, init: 0}
		mut v := []int{len: max_m, init: 0}
		for edge in 0 .. m {
			a, b := input[2 + 2 * edge], input[3 + 2 * edge]
			if a < 0 || a >= b || b >= n64 { return -1 }
			u[edge], v[edge] = int(a), int(b)
			for prior in 0 .. edge { if u[prior] == u[edge] && v[prior] == v[edge] { return -1 } }
		}
		mut selected := []bool{len: max_m, init: false}
		original := distances(n, m, u, v, selected, false)
		for round := 0; round <= m; round++ {
			current := distances(n, m, u, v, selected, true)
			source, target := n, n
			for a in 0 .. n {
				if source != n { break }
				for b in a + 1 .. n {
					if original[a * max_n + b] < inf && current[a * max_n + b] > original[a * max_n + b] + 2 {
						source, target = a, b
						break
					}
				}
			}
			if source == n { break }
			if round == m { return -1 }
			mut vertex := source
			for vertex != target {
				mut next := n
				for neighbor in 0 .. n {
					if neighbor == vertex || original[neighbor * max_n + target] + 1 != original[vertex * max_n + target] { continue }
					for edge in 0 .. m {
						if (u[edge] == vertex && v[edge] == neighbor) || (v[edge] == vertex && u[edge] == neighbor) {
							next = neighbor
							selected[edge] = true
							break
						}
					}
					if next != n { break }
				}
				if next == n { return -1 }
				vertex = next
			}
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
