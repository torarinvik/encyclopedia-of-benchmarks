const max_nodes = 256

struct SearchNode {
	x      int
	y      int
	g      int
	f      int
	parent int
}

fn write_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte_index in 0 .. 8 {
			output[offset + byte_index] = u8((bits >> (byte_index * 8)) & 255)
		}
	}
}

@[export: 'astar']
pub fn astar(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 6 { return -1 }
		rows64, cols64 := input[0], input[1]
		sx64, sy64, gx64, gy64 := input[2], input[3], input[4], input[5]
		if rows64 < 1 || rows64 > 16 || cols64 < 1 || cols64 > 16 ||
			sx64 < 0 || sx64 >= rows64 || sy64 < 0 || sy64 >= cols64 ||
			gx64 < 0 || gx64 >= rows64 || gy64 < 0 || gy64 >= cols64 { return -1 }
		rows, cols := int(rows64), int(cols64)
		sx, sy, gx, gy := int(sx64), int(sy64), int(gx64), int(gy64)
		dx := [-1, -1, -1, 0, 0, 1, 1, 1]
		dy := [-1, 0, 1, -1, 1, -1, 0, 1]
		mut nodes := [max_nodes]SearchNode{}
		mut open := [max_nodes]int{}
		mut node_count := 1
		mut open_count := 1
		nodes[0] = SearchNode{x: sx, y: sy, g: 0, f: 0, parent: -1}
		open[0] = 0
		mut current := 0
		mut found := false
		for open_count > 0 {
			mut best := 0
			for i in 1 .. open_count {
				if nodes[open[i]].f < nodes[open[best]].f { best = i }
			}
			current = open[best]
			for i in best + 1 .. open_count { open[i - 1] = open[i] }
			open_count--
			current_node := nodes[current]
			if current_node.x == gx && current_node.y == gy { found = true; break }
			for neighbor in 0 .. 8 {
				x := current_node.x + dx[neighbor]
				y := current_node.y + dy[neighbor]
				if x < 0 || x >= rows || y < 0 || y >= cols { continue }
				if node_count >= max_nodes || open_count >= max_nodes { return -1 }
				g := current_node.g + 1
				ex, ey := gx - x, gy - y
				nodes[node_count] = SearchNode{x: x, y: y, g: g, f: g + ex * ex + ey * ey, parent: current}
				open[open_count] = node_count
				open_count++
				node_count++
			}
		}
		if !found { return -1 }
		mut path_count := 0
		mut cursor := current
		for cursor >= 0 { path_count++; cursor = nodes[cursor].parent }
		output_bytes := path_count * 16
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut offset := output_bytes
		cursor = current
		for cursor >= 0 {
			offset -= 16
			write_i64(mut output, offset, i64(nodes[cursor].x))
			write_i64(mut output, offset + 8, i64(nodes[cursor].y))
			cursor = nodes[cursor].parent
		}
		return i64(output_bytes)
	}
}
