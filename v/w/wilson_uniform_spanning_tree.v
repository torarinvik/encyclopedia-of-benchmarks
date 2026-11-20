module wilson_uniform_spanning_tree

const max_n = 8
const max_edges = 28
const walk_limit = 64
const max_input = 4 + 2 * max_edges + walk_limit * (max_n - 1)

@[export: 'wilson_uniform_spanning_tree']
pub fn wilson_uniform_spanning_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input + 1 { return -1 }
		n_raw, m_raw, root_raw := input[0], input[1], input[2]
		if n_raw < 1 || n_raw > max_n || m_raw < 0 || m_raw > max_edges { return -1 }
		n, m := int(n_raw), int(m_raw)
		if root_raw < 0 || root_raw >= n_raw { return -1 }
		root := int(root_raw)
		q_at := 3 + 2 * m
		if length <= usize(q_at) { return -1 }
		q_raw := input[q_at]
		if q_raw < 0 || q_raw > i64(walk_limit * (n - 1)) { return -1 }
		q := int(q_raw)
		if length != usize(q_at + 1 + q) { return -1 }

		mut neighbors := [max_n][max_n - 1]int{init: 0}
		mut degree := [max_n]int{init: 0}
		mut prev_u := i64(-1)
		mut prev_v := i64(-1)
		for edge in 0 .. m {
			u_raw, v_raw := input[3 + 2 * edge], input[4 + 2 * edge]
			if u_raw < 0 || u_raw >= v_raw || v_raw >= n_raw { return -1 }
			if edge > 0 && (u_raw < prev_u || (u_raw == prev_u && v_raw <= prev_v)) { return -1 }
			prev_u, prev_v = u_raw, v_raw
			u, v := int(u_raw), int(v_raw)
			neighbors[u][degree[u]] = v
			degree[u]++
			neighbors[v][degree[v]] = u
			degree[v]++
		}
		for draw in 0 .. q {
			value := input[q_at + 1 + draw]
			if value < 0 || value > max_n - 2 { return -1 }
		}

		mut seen := [max_n]bool{init: false}
		mut queue := [max_n]int{init: 0}
		mut head, mut tail := 0, 0
		seen[root] = true
		queue[tail] = root
		tail++
		for head < tail {
			at := queue[head]
			head++
			for k in 0 .. degree[at] {
				to := neighbors[at][k]
				if !seen[to] {
					seen[to] = true
					queue[tail] = to
					tail++
				}
			}
		}
		for vertex in 0 .. n { if !seen[vertex] { return -1 } }

		mut in_tree := [max_n]bool{init: false}
		mut successor := [max_n]int{init: -1}
		in_tree[root] = true
		mut cursor := 0
		for start in 0 .. n {
			if in_tree[start] { continue }
			mut current, mut steps := start, 0
			for !in_tree[current] {
				if steps >= walk_limit || cursor >= q { return -1 }
				choice := int(input[q_at + 1 + cursor])
				if choice >= degree[current] { return -1 }
				successor[current] = neighbors[current][choice]
				current = successor[current]
				cursor++
				steps++
			}
			current = start
			for !in_tree[current] { in_tree[current] = true; current = successor[current] }
		}
		if cursor != q { return -1 }

		required := 16 * (n - 1)
		if (required > 0 && output == nil) || capacity < usize(required) { return -2 }
		offset := 0
		for child in 0 .. n {
			if child == root { continue }
			write_i64_le(output, offset, i64(child))
			offset += 8
			write_i64_le(output, offset, i64(successor[child]))
			offset += 8
		}
		return i64(required)
	}
}

fn write_i64_le(output &mut u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
	}
}
