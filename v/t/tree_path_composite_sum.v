module tree_path_composite_sum

const max_n = 32
const max_input = 5 * max_n - 3
const max_cells = max_n * max_n
const mod = i64(998244353)

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'tree_path_composite_sum']
pub fn tree_path_composite_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input) {
			return -1
		}
		n_value := input[0]
		if n_value < 1 || n_value > max_n {
			return -1
		}
		n := int(n_value)
		if length != usize(1 + n + 4 * (n - 1)) {
			return -1
		}
		mut vertex_value := []i64{len: max_n}
		for vertex in 0 .. n {
			vertex_value[vertex] = input[1 + vertex]
			if vertex_value[vertex] < 0 || vertex_value[vertex] >= mod {
				return -1
			}
		}
		mut adjacent := []bool{len: max_cells}
		mut multiplier := []i64{len: max_cells}
		mut addend := []i64{len: max_cells}
		mut dsu_parent := []int{len: max_n}
		mut dsu_size := []int{len: max_n}
		for vertex in 0 .. n {
			dsu_parent[vertex] = vertex
			dsu_size[vertex] = 1
		}
		mut offset := 1 + n
		for _ in 0 .. n - 1 {
			u_value := input[offset]
			v_value := input[offset + 1]
			b := input[offset + 2]
			c_value := input[offset + 3]
			offset += 4
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
				u_value == v_value || b < 1 || b >= mod || c_value < 0 || c_value >= mod {
				return -1
			}
			u := int(u_value)
			v := int(v_value)
			mut root_u := find_root(mut dsu_parent, u)
			mut root_v := find_root(mut dsu_parent, v)
			if root_u == root_v {
				return -1
			}
			if dsu_size[root_u] < dsu_size[root_v] {
				temporary := root_u
				root_u = root_v
				root_v = temporary
			}
			dsu_parent[root_v] = root_u
			dsu_size[root_u] += dsu_size[root_v]
			uv := u * max_n + v
			vu := v * max_n + u
			adjacent[uv] = true
			adjacent[vu] = true
			multiplier[uv] = b
			multiplier[vu] = b
			addend[uv] = c_value
			addend[vu] = c_value
		}

		mut order := []int{len: max_n}
		mut stack := []int{len: max_n}
		mut parent := []int{len: max_n, init: -2}
		parent[0] = -1
		mut top := 1
		mut order_count := 0
		stack[0] = 0
		for top > 0 {
			top--
			u := stack[top]
			order[order_count] = u
			order_count++
			for v in 0 .. n {
				cell := u * max_n + v
				if adjacent[cell] && v != parent[u] {
					parent[v] = u
					stack[top] = v
					top++
				}
			}
		}

		mut down_sum := []i64{len: max_n}
		mut up_sum := []i64{len: max_n}
		mut answer := []i64{len: max_n}
		mut down_count := []int{len: max_n}
		mut up_count := []int{len: max_n}
		for position := order_count - 1; position >= 0; position-- {
			u := order[position]
			down_sum[u] = vertex_value[u]
			down_count[u] = 1
			for v in 0 .. n {
				cell := u * max_n + v
				if adjacent[cell] && parent[v] == u {
					contribution := (multiplier[cell] * down_sum[v] +
						addend[cell] * i64(down_count[v])) % mod
					down_sum[u] = (down_sum[u] + contribution) % mod
					down_count[u] += down_count[v]
				}
			}
		}
		for position in 0 .. order_count {
			u := order[position]
			mut total_sum := vertex_value[u]
			mut total_count := 1
			if parent[u] >= 0 {
				total_sum = (total_sum + up_sum[u]) % mod
				total_count += up_count[u]
			}
			for v in 0 .. n {
				cell := u * max_n + v
				if adjacent[cell] && parent[v] == u {
					total_sum = (total_sum + multiplier[cell] * down_sum[v] +
						addend[cell] * i64(down_count[v])) % mod
					total_count += down_count[v]
				}
			}
			answer[u] = total_sum
			for v in 0 .. n {
				cell := u * max_n + v
				if adjacent[cell] && parent[v] == u {
					contribution := (multiplier[cell] * down_sum[v] +
						addend[cell] * i64(down_count[v])) % mod
					outside_sum := (total_sum - contribution + mod) % mod
					outside_count := total_count - down_count[v]
					up_sum[v] = (multiplier[cell] * outside_sum +
						addend[cell] * i64(outside_count)) % mod
					up_count[v] = outside_count
				}
			}
		}
		required := 8 * n
		if output == nil || capacity < usize(required) {
			return -2
		}
		for vertex in 0 .. n {
			store_le(mut output, 8 * vertex, answer[vertex])
		}
		return i64(required)
	}
}
