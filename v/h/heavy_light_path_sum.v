module heavy_light_path_max

const max_n = 64
const max_q = 128

fn put_i64(mut output &u8, slot int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[slot * 8 + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn max_i64(a i64, b i64) i64 {
	if a > b { return a }
	return b
}

fn range_max(tree &i64, n int, left int, right int) i64 {
	unsafe {
		mut l := left + n
		mut r := right + n + 1
		mut maximum := i64(-2147483648)
		for l < r {
			if (l & 1) != 0 { maximum = max_i64(maximum, tree[l]); l++ }
			if (r & 1) != 0 { r--; maximum = max_i64(maximum, tree[r]) }
			l /= 2
			r /= 2
		}
		return maximum
	}
}

fn point_set(tree &i64, n int, position int, value i64) {
	unsafe {
		mut p := position + n
		tree[p] = value
		for p > 1 {
			p /= 2
			tree[p] = max_i64(tree[p * 2], tree[p * 2 + 1])
		}
	}
}

fn path_max(tree &i64, n int, parent &int, depth &int, head &int, position &int, a_value int, b_value int) i64 {
	unsafe {
		mut a := a_value
		mut b := b_value
		mut maximum := i64(-2147483648)
		for head[a] != head[b] {
			if depth[head[a]] < depth[head[b]] { a, b = b, a }
			maximum = max_i64(maximum, range_max(tree, n, position[head[a]], position[a]))
			a = parent[head[a]]
		}
		if depth[a] > depth[b] { a, b = b, a }
		return max_i64(maximum, range_max(tree, n, position[a], position[b]))
	}
}

@[export: 'heavy_light_path_max']
pub fn heavy_light_path_max(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		nv := input[0]
		qv := input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n := int(nv)
		q := int(qv)
		if length != usize(3 * n + 3 * q) { return -1 }

		mut values := [max_n]i64{init: 0}
		mut cursor := 2
		for v in 0 .. n {
			values[v] = input[cursor]
			if values[v] < -2147483648 || values[v] > 2147483647 { return -1 }
			cursor++
		}
		mut adjacency := [max_n * max_n]int{init: 0}
		mut degree := [max_n]int{init: 0}
		for _ in 0 .. (n - 1) {
			uv := input[cursor]
			vv := input[cursor + 1]
			cursor += 2
			if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv { return -1 }
			u := int(uv)
			v := int(vv)
			for i in 0 .. degree[u] {
				if adjacency[u * max_n + i] == v { return -1 }
			}
			adjacency[u * max_n + degree[u]] = v
			degree[u]++
			adjacency[v * max_n + degree[v]] = u
			degree[v]++
		}

		mut parent := [max_n]int{init: -2}
		mut depth := [max_n]int{init: 0}
		mut order := [max_n]int{init: 0}
		mut stack := [max_n]int{init: 0}
		parent[0] = -1
		mut top := 1
		mut order_count := 0
		stack[0] = 0
		for top > 0 {
			top--
			u := stack[top]
			order[order_count] = u
			order_count++
			for i in 0 .. degree[u] {
				v := adjacency[u * max_n + i]
				if v == parent[u] { continue }
				if parent[v] != -2 { return -1 }
				parent[v] = u
				depth[v] = depth[u] + 1
				stack[top] = v
				top++
			}
		}
		if order_count != n { return -1 }

		mut subtree := [max_n]int{init: 1}
		mut heavy := [max_n]int{init: -1}
		for index := n - 1; index > 0; index-- {
			v := order[index]
			p := parent[v]
			subtree[p] += subtree[v]
			if heavy[p] < 0 || subtree[v] > subtree[heavy[p]] { heavy[p] = v }
		}
		mut head := [max_n]int{init: 0}
		mut position := [max_n]int{init: 0}
		mut todo_vertex := [max_n]int{init: 0}
		mut todo_head := [max_n]int{init: 0}
		mut base := [max_n]i64{init: 0}
		top = 1
		mut timer := 0
		todo_vertex[0] = 0
		todo_head[0] = 0
		for top > 0 {
			top--
			mut u := todo_vertex[top]
			chain := todo_head[top]
			for u >= 0 {
				head[u] = chain
				position[u] = timer
				base[timer] = values[u]
				timer++
				for i in 0 .. degree[u] {
					v := adjacency[u * max_n + i]
					if parent[v] == u && v != heavy[u] {
						todo_vertex[top] = v
						todo_head[top] = v
						top++
					}
				}
				u = heavy[u]
			}
		}
		mut segment := [max_n * 2]i64{init: 0}
		for i in 0 .. n { segment[n + i] = base[i] }
		for i := n - 1; i > 0; i-- { segment[i] = max_i64(segment[i * 2], segment[i * 2 + 1]) }

		mut results := [max_q]i64{init: 0}
		mut result_count := 0
		operations := cursor
		for i in 0 .. q {
			op := input[operations + 3 * i]
			av := input[operations + 3 * i + 1]
			bv := input[operations + 3 * i + 2]
			if op == 0 {
				if av < 0 || av >= nv || bv < -2147483648 || bv > 2147483647 { return -1 }
				values[int(av)] = bv
				point_set(&segment[0], n, position[int(av)], bv)
			} else if op == 1 {
				if av < 0 || av >= nv || bv < 0 || bv >= nv { return -1 }
				results[result_count] = path_max(&segment[0], n, &parent[0], &depth[0], &head[0], &position[0], int(av), int(bv))
				result_count++
			} else { return -1 }
		}
		output_bytes := result_count * 8
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		for i in 0 .. result_count { put_i64(mut output, i, results[i]) }
		return i64(output_bytes)
	}
}
