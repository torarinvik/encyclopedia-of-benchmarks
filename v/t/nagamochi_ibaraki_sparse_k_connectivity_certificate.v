module nagamochi_ibaraki_sparse_k_connectivity_certificate
import core.c

const max_n = 8
const max_m = 28
const max_input = 60

fn put(out &u8, at int, value i64) {
	bits := u64(value)
	unsafe { for i in 0 .. 8 { out[at + i] = u8((bits >> (8 * i)) & 255) } }
}

@[export: 'nagamochi_ibaraki_sparse_k_connectivity_certificate']
pub fn nagamochi_ibaraki_sparse_k_connectivity_certificate(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n64, m64, k64 := input[0], input[1], input[2]
		if n64 < 3 || n64 > 8 || m64 < 0 || m64 > 28 || k64 < 1 || k64 > 3 || length != usize(3 + 2 * m64) { return -1 }
		n, m, k := int(n64), int(m64), int(k64)
		mut u := []int{len: max_m, init: 0}
		mut v := []int{len: max_m, init: 0}
		mut incident := []int{len: max_n * max_n, init: 0}
		mut degree := []int{len: max_n, init: 0}
		for e in 0 .. m {
			a, b := input[3 + 2 * e], input[4 + 2 * e]
			if a < 0 || a >= b || b >= n64 { return -1 }
			u[e], v[e] = int(a), int(b)
			for prior in 0 .. e { if u[prior] == u[e] && v[prior] == v[e] { return -1 } }
			incident[u[e] * max_n + degree[u[e]]] = e
			degree[u[e]]++
			incident[v[e] * max_n + degree[v[e]]] = e
			degree[v[e]]++
		}
		bytes := 8 * (m + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut rank := []int{len: max_n, init: 0}
		mut layer := []int{len: max_m, init: 0}
		mut scanned_vertex := []bool{len: max_n, init: false}
		mut scanned_edge := []bool{len: max_m, init: false}
		for _ in 0 .. n {
			mut x := n
			for vertex in 0 .. n {
				if !scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x]) { x = vertex }
			}
			for slot in 0 .. degree[x] {
				e := incident[x * max_n + slot]
				if scanned_edge[e] { continue }
				y := u[e]
				if y == x { y = v[e] }
				layer[e] = rank[y] + 1
				if rank[x] == rank[y] { rank[x]++ }
				rank[y]++
				scanned_edge[e] = true
			}
			scanned_vertex[x] = true
		}
		put(output, 0, i64(m))
		for e in 0 .. m {
			mut visible := layer[e]
			if visible > k { visible = 0 }
			put(output, 8 * (e + 1), i64(visible))
		}
		return i64(bytes)
	}
}
