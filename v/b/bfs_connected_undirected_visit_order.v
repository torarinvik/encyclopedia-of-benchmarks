module bfs_connected_undirected_visit_order

const max_vertices = 40
const max_edges = 780

fn put_i64(output &u8, slot int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[slot * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'bfs_connected_undirected_visit_order']
pub fn bfs_connected_undirected_visit_order(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_vertices || input[1] < 0 || input[1] > max_edges || input[2] != 0 { return -1 }
		vertices := int(input[0])
		edge_count := int(input[1])
		if length != usize(3 + 2 * edge_count) { return -1 }

		mut adjacency := [max_vertices]u64{init: 0}
		for edge in 0 .. edge_count {
			left_value := input[3 + 2 * edge]
			right_value := input[4 + 2 * edge]
			if left_value < 0 || right_value < 0 || left_value >= i64(vertices) || right_value >= i64(vertices) { return -1 }
			left := int(left_value)
			right := int(right_value)
			adjacency[left] |= u64(1) << u64(right)
			adjacency[right] |= u64(1) << u64(left)
		}
		mut visited := [max_vertices]bool{init: false}
		mut queue := [max_vertices]int{init: 0}
		mut order := [max_vertices]int{init: 0}
		mut head := 0
		mut tail := 1
		mut count := 0
		visited[0] = true
		queue[0] = 0
		for head < tail {
			vertex := queue[head]
			head++
			order[count] = vertex
			count++
			for neighbor := 0; neighbor < vertices; neighbor++ {
				if adjacency[vertex] & (u64(1) << u64(neighbor)) != 0 && !visited[neighbor] {
					visited[neighbor] = true
					queue[tail] = neighbor
					tail++
				}
			}
		}
		if count != vertices { return -1 }
		if output == nil || capacity < usize(vertices * 8) { return -2 }
		for index in 0 .. count { put_i64(output, index, i64(order[index])) }
		return i64(count)
	}
}
