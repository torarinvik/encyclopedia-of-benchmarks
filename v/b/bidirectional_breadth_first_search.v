module bidirectional_breadth_first_search

const max_dimension = 8
const max_cells = max_dimension * max_dimension
const max_input_length = 5 + max_cells
const max_output_values = 1 + max_cells

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'bidirectional_breadth_first_search']
pub fn bidirectional_breadth_first_search(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		rows_value, cols_value := input[0], input[1]
		if rows_value < 1 || rows_value > max_dimension || cols_value < 1 || cols_value > max_dimension { return -1 }
		rows, cols := int(rows_value), int(cols_value)
		cells := rows * cols
		start_value, goal_value, blocked_count_value := input[2], input[3], input[4]
		if start_value < 0 || start_value >= i64(cells) || goal_value < 0 || goal_value >= i64(cells) || blocked_count_value < 0 || blocked_count_value > i64(cells) { return -1 }
		blocked_count := int(blocked_count_value)
		if length != usize(5 + blocked_count) { return -1 }
		start, goal := int(start_value), int(goal_value)
		mut blocked := [max_cells]bool{}
		for index in 0 .. blocked_count {
			value := input[5 + index]
			if value < 0 || value >= i64(cells) { return -1 }
			cell := int(value)
			if blocked[cell] { return -1 }
			blocked[cell] = true
		}
		if blocked[start] || blocked[goal] { return -1 }

		mut distance := [2 * max_cells]i64{init: -1}
		mut parent := [2 * max_cells]i64{init: -1}
		mut queues := [2 * max_cells]int{}
		mut head := [2]int{}
		mut tail := [2]int{1, 1}
		mut meeting := if start == goal { start } else { -1 }
		distance[start] = 0
		distance[max_cells + goal] = 0
		queues[0] = start
		queues[max_cells] = goal
		for meeting < 0 && head[0] < tail[0] && head[1] < tail[1] {
			for side in 0 .. 2 {
				if meeting >= 0 { break }
				layer_end := tail[side]
				for head[side] < layer_end {
					node := queues[side * max_cells + head[side]]
					head[side]++
					row, col := node / cols, node % cols
					mut neighbors := [4]int{-1, -1, -1, -1}
					if row > 0 { neighbors[0] = node - cols }
					if col > 0 { neighbors[1] = node - 1 }
					if row + 1 < rows { neighbors[2] = node + cols }
					if col + 1 < cols { neighbors[3] = node + 1 }
					for neighbor in neighbors {
						if neighbor < 0 || blocked[neighbor] || distance[side * max_cells + neighbor] >= 0 { continue }
						distance[side * max_cells + neighbor] = distance[side * max_cells + node] + 1
						parent[side * max_cells + neighbor] = i64(node)
						queues[side * max_cells + tail[side]] = neighbor
						tail[side]++
						if distance[(1 - side) * max_cells + neighbor] >= 0 { meeting = neighbor; break }
					}
					if meeting >= 0 { break }
				}
			}
		}
		mut encoded := [max_output_values]i64{}
		mut value_count := 1
		if meeting < 0 {
			encoded[0] = 0
		} else {
			mut reverse_path := [max_cells]int{}
			mut prefix_count := 0
			mut path_count := 0
			mut current := meeting
			for current >= 0 {
				reverse_path[prefix_count] = current
				prefix_count++
				if current == start { break }
				current = int(parent[current])
			}
			for index in 0 .. prefix_count {
				encoded[1 + path_count] = i64(reverse_path[prefix_count - 1 - index])
				path_count++
			}
			current = int(parent[max_cells + meeting])
			for current >= 0 {
				encoded[1 + path_count] = i64(current)
				path_count++
				current = int(parent[max_cells + current])
			}
			encoded[0] = i64(path_count)
			value_count += path_count
		}
		required := value_count * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }
		for index in 0 .. value_count { put_i64(mut output, index * 8, encoded[index]) }
		return i64(required)
	}
}
