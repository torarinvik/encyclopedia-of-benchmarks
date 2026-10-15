module bfs_queue

const max_vertex_count = 64
const max_edge_count = 2046
const max_input_length = 4 + 2 * max_edge_count

@[export: 'bfs_queue']
pub fn bfs_queue(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 4 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_vertex_count || input[3] < 0 || input[3] > max_edge_count { return -1 }
		vertex_count := int(input[0])
		source_arg := input[1]
		target_arg := input[2]
		edge_count := int(input[3])
		if source_arg < 0 || source_arg >= i64(vertex_count) || target_arg < 0 ||
			target_arg >= i64(vertex_count) || int(length) != 4 + 2 * edge_count { return -1 }
		mut adjacency := []u64{len: max_vertex_count}
		for edge in 0 .. edge_count {
			left_arg := input[4 + 2 * edge]
			right_arg := input[5 + 2 * edge]
			if left_arg < 0 || right_arg < 0 || left_arg >= i64(vertex_count) || right_arg >= i64(vertex_count) { return -1 }
			left := int(left_arg)
			right := int(right_arg)
			adjacency[left] |= u64(1) << right
			adjacency[right] |= u64(1) << left
		}
		source := int(source_arg)
		target := int(target_arg)
		mut predecessor := []int{len: max_vertex_count, init: -1}
		mut visited := []bool{len: max_vertex_count}
		mut queue := []int{len: max_vertex_count}
		predecessor[source] = source
		visited[source] = true
		mut head := 0
		mut tail := 1
		queue[0] = source
		mut found := source == target
		for head < tail && !found {
			current := queue[head]
			head++
			for neighbor in 0 .. vertex_count {
				if adjacency[current] & (u64(1) << neighbor) == 0 || visited[neighbor] { continue }
				visited[neighbor] = true
				predecessor[neighbor] = current
				if neighbor == target {
					found = true
					break
				}
				queue[tail] = neighbor
				tail++
			}
		}
		if !found {
			if output_capacity < 1 { return -2 }
			output[0] = 0
			return 1
		}
		mut path := []u8{len: max_vertex_count}
		mut path_length := 0
		mut current := target
		for current != source {
			path[path_length] = u8(current)
			path_length++
			current = predecessor[current]
		}
		path[path_length] = u8(source)
		path_length++
		if output_capacity < usize(path_length + 1) { return -2 }
		output[0] = 1
		for index in 0 .. path_length { output[index + 1] = path[index] }
		return i64(path_length + 1)
	}
}
