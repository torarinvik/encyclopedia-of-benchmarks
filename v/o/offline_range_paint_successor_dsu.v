fn paint_find_successor(mut parent [65]i64, start int) int {
	mut node := start
	mut root := start
	for int(parent[root]) != root { root = int(parent[root]) }
	for int(parent[node]) != node {
		next := int(parent[node])
		parent[node] = i64(root)
		node = next
	}
	return root
}

@[export: 'offline_range_paint_successor_dsu']
pub fn offline_range_paint_successor_dsu(input &i64, length usize) i64 {
	if length < 2 || length > 195 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > 64 || q_value < 0 || q_value > 64 { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(2 + 3*q) { return -1 }
		mut left := [64]i64{}
		mut right := [64]i64{}
		mut color := [64]i64{}
		for j in 0 .. q {
			left[j], right[j], color[j] = input[2+3*j], input[3+3*j], input[4+3*j]
			if left[j] < 0 || left[j] > right[j] || right[j] >= n_value || color[j] < -1000 || color[j] > 1000 { return -1 }
		}
		mut parent := [65]i64{}
		mut final_color := [64]i64{}
		for i in 0 .. n+1 { parent[i] = i64(i) }
		mut j := q
		for j > 0 {
			j--
			operation := j
			mut cell := paint_find_successor(mut parent, int(left[operation]))
			for cell <= int(right[operation]) {
				final_color[cell] = color[operation]
				parent[cell] = i64(paint_find_successor(mut parent, cell+1))
				cell = paint_find_successor(mut parent, cell)
			}
		}
		mut checksum := i64(0)
		for i in 0 .. n { checksum += i64(i+1) * (final_color[i] + 1001) }
		return checksum
	}
}
