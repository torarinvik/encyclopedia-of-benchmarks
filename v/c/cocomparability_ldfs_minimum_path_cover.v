module cocomparability_ldfs_minimum_path_cover

const max_vertices = 8
const max_parseable_length = 18

@[export: 'cocomparability_ldfs_minimum_path_cover']
pub fn cocomparability_ldfs_minimum_path_cover(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_vertices { return -1 }
		n := int(n_value)
		if length != usize(1 + 2*n) { return -1 }
		full := (u16(1) << u16(n)) - u16(1)
		mut adjacency := []u16{len: max_vertices}
		mut order := []int{len: max_vertices}
		mut rank := []int{len: max_vertices}
		mut position := []int{len: max_vertices}
		mut seen_order := []bool{len: max_vertices}
		for v in 0 .. n {
			row := input[1 + v]
			if row < 0 { return -1 }
			if u64(row) > u64(full) || row & (i64(1) << v) != 0 { return -1 }
			adjacency[v] = u16(row)
		}
		for u in 0 .. n {
			for v in 0 .. n {
				if ((adjacency[u] >> u16(v)) & u16(1)) != ((adjacency[v] >> u16(u)) & u16(1)) { return -1 }
			}
		}
		for i in 0 .. n {
			value := input[1 + n + i]
			if value < 0 || value >= n_value || seen_order[int(value)] { return -1 }
			order[i] = int(value)
			rank[int(value)] = i
			seen_order[int(value)] = true
		}
		for i in 0 .. n {
			for j in i + 1 .. n {
				for k in j + 1 .. n {
					a, b, c := order[i], order[j], order[k]
					if adjacency[a] & (u16(1) << u16(c)) != 0 && adjacency[a] & (u16(1) << u16(b)) == 0 && adjacency[b] & (u16(1) << u16(c)) == 0 { return -1 }
				}
			}
		}
		mut reached := []bool{len: max_vertices}
		mut queue := []int{cap: max_vertices}
		queue << 0
		reached[0] = true
		mut head := 0
		for head < queue.len {
			u := queue[head]
			head++
			for v in 0 .. n {
				if adjacency[u] & (u16(1) << u16(v)) != 0 && !reached[v] {
					reached[v] = true
					queue << v
				}
			}
		}
		for v in 0 .. n { if !reached[v] { return -1 } }

		mut labels := []u64{len: max_vertices}
		mut visited := []bool{len: max_vertices}
		mut ldfs := []int{len: max_vertices}
		for step in 1 .. n + 1 {
			mut chosen := -1
			for v in 0 .. n {
				if !visited[v] && (chosen < 0 || labels[v] > labels[chosen] || (labels[v] == labels[chosen] && rank[v] > rank[chosen])) { chosen = v }
			}
			ldfs[step - 1] = chosen
			visited[chosen] = true
			for v in 0 .. n {
				if !visited[v] && adjacency[chosen] & (u16(1) << u16(v)) != 0 {
					labels[v] = (labels[v] >> 4) | (u64(step) << 60)
				}
			}
		}
		for i in 0 .. n { position[ldfs[i]] = i }
		for v in 0 .. n { visited[v] = false }
		mut paths := 0
		for {
			mut current := -1
			for v in 0 .. n {
				if !visited[v] && (current < 0 || position[v] > position[current]) { current = v }
			}
			if current < 0 { break }
			paths++
			visited[current] = true
			for {
				mut next := -1
				for v in 0 .. n {
					if !visited[v] && adjacency[current] & (u16(1) << u16(v)) != 0 && (next < 0 || position[v] > position[next]) { next = v }
				}
				if next < 0 { break }
				visited[next] = true
				current = next
			}
		}
		return i64(paths)
	}
}
