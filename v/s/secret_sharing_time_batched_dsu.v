module secret_sharing_time_batched_dsu

const max_n = 16
const max_m = 20

fn secret_find(mut parent []int, node_input int) int {
	mut node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn secret_join(mut parent []int, mut sizes []int, left int, right int) {
	mut a := secret_find(mut parent, left)
	mut b := secret_find(mut parent, right)
	if a == b { return }
	if sizes[a] < sizes[b] { a, b = b, a }
	parent[b] = a
	sizes[a] += sizes[b]
}

@[export: 'secret_sharing_time_batched_dsu']
pub fn secret_sharing_time_batched_dsu(input &i64, length usize) i64 {
	if length < 3 || length > 64 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value, first_value, m_value := input[0], input[1], input[2]
		if n_value < 2 || n_value > max_n || first_value < 1 || first_value >= n_value
			|| m_value < 0 || m_value > max_m { return -1 }
		n, first, m := int(n_value), int(first_value), int(m_value)
		if length != usize(3 + 3*m) { return -1 }
		for i in 0 .. m {
			u, v, time := input[3+3*i], input[4+3*i], input[5+3*i]
			if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v || time < 1 || time > 20 {
				return -1
			}
		}
		mut parent := []int{len: max_n, cap: max_n}
		mut sizes := []int{len: max_n, cap: max_n, init: 1}
		for node in 0 .. n { parent[node] = node }
		secret_join(mut parent, mut sizes, 0, first)
		for time in 1 .. 21 {
			mut touched := []bool{len: max_n, cap: max_n}
			for i in 0 .. m {
				u, v := int(input[3+3*i]), int(input[4+3*i])
				if input[5+3*i] == i64(time) {
					secret_join(mut parent, mut sizes, u, v)
					touched[u] = true
					touched[v] = true
				}
			}
			known_root := secret_find(mut parent, 0)
			for node in 0 .. n {
				if touched[node] && secret_find(mut parent, node) != known_root {
					parent[node] = node
					sizes[node] = 1
				}
			}
		}
		known_root := secret_find(mut parent, 0)
		mut result := i64(0)
		for node in 0 .. n {
			if secret_find(mut parent, node) == known_root { result |= i64(1) << node }
		}
		return result
	}
}
