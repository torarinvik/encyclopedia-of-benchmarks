module lowest_common_ancestor

@[export: 'lowest_common_ancestor']
pub fn lowest_common_ancestor(input &i64, length usize) i64 {
	if length < 4 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 1023 { return -1 }
		count := int(input[0])
		if int(length) != 4 + 3 * count { return -1 }
		for field in 1 .. 4 {
			if input[field] < 0 || input[field] >= i64(count) { return -1 }
		}
		if input[2] == input[3] { return -1 }
		root := int(input[1])
		p := int(input[2])
		q := int(input[3])
		mut parent := [1023]i64{}
		mut stack := [1023]int{}
		mut path_p := [1023]int{}
		mut path_q := [1023]int{}
		mut seen := [1023]bool{}
		for node in 0 .. count { parent[node] = -1 }
		for node in 0 .. count {
			offset := 4 + 3 * node
			if input[offset] < -1_000_000_000 || input[offset] > 1_000_000_000 { return -1 }
			for edge in 1 .. 3 {
				child := input[offset + edge]
				if child < -1 || child >= i64(count) { return -1 }
				if child >= 0 {
					child_index := int(child)
					if parent[child_index] != -1 { return -1 }
					parent[child_index] = i64(node)
				}
			}
		}
		if parent[root] != -1 { return -1 }
		for node in 0 .. count {
			if node != root && parent[node] == -1 { return -1 }
		}
		mut top := 0
		mut reached := 0
		stack[top] = root
		top++
		for top > 0 {
			top--
			node := stack[top]
			if seen[node] { return -1 }
			seen[node] = true
			reached++
			offset := 4 + 3 * node
			for edge in 1 .. 3 {
				child := input[offset + edge]
				if child >= 0 {
					stack[top] = int(child)
					top++
				}
			}
		}
		if reached != count { return -1 }
		mut depth_p := 0
		mut depth_q := 0
		mut current := p
		path_p[depth_p] = current
		depth_p++
		for current != root {
			current = int(parent[current])
			path_p[depth_p] = current
			depth_p++
		}
		current = q
		path_q[depth_q] = current
		depth_q++
		for current != root {
			current = int(parent[current])
			path_q[depth_q] = current
			depth_q++
		}
		mut ancestor := i64(-1)
		for depth_p > 0 && depth_q > 0 {
			if path_p[depth_p - 1] != path_q[depth_q - 1] { break }
			ancestor = i64(path_p[depth_p - 1])
			depth_p--
			depth_q--
		}
		return ancestor
	}
}
