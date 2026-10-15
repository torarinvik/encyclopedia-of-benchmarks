package astar

import "core:c"

MAX_NODES :: 256
Search_Node :: struct { x, y, g, f, parent: i32 }
DX :: [8]i32{-1, -1, -1, 0, 0, 1, 1, 1}
DY :: [8]i32{-1, 0, 1, -1, 1, -1, 0, 1}

write_i64 :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for shift: u32 = 0; shift < 64; shift += 8 {
		output[offset + usize(shift / 8)] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
astar :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	rows64, cols64 := input[0], input[1]
	sx64, sy64, gx64, gy64 := input[2], input[3], input[4], input[5]
	if rows64 < 1 || rows64 > 16 || cols64 < 1 || cols64 > 16 ||
		sx64 < 0 || sx64 >= rows64 || sy64 < 0 || sy64 >= cols64 ||
		gx64 < 0 || gx64 >= rows64 || gy64 < 0 || gy64 >= cols64 do return -1
	rows, cols := i32(rows64), i32(cols64)
	sx, sy, gx, gy := i32(sx64), i32(sy64), i32(gx64), i32(gy64)
	var nodes: [MAX_NODES]Search_Node
	var open: [MAX_NODES]i32
	node_count, open_count := 1, 1
	nodes[0] = Search_Node{x = sx, y = sy, g = 0, f = 0, parent = -1}
	open[0] = 0
	current := i32(0)
	found := false
	for open_count > 0 {
		best := 0
		for i := 1; i < open_count; i += 1 { if nodes[open[i]].f < nodes[open[best]].f { best = i } }
		current = open[best]
		for i := best + 1; i < open_count; i += 1 { open[i - 1] = open[i] }
		open_count -= 1
		current_node := nodes[current]
		if current_node.x == gx && current_node.y == gy { found = true; break }
		for neighbor := 0; neighbor < 8; neighbor += 1 {
			x := current_node.x + DX[neighbor]
			y := current_node.y + DY[neighbor]
			if x < 0 || x >= rows || y < 0 || y >= cols do continue
			if node_count >= MAX_NODES || open_count >= MAX_NODES do return -1
			g := current_node.g + 1
			ex, ey := gx - x, gy - y
			nodes[node_count] = Search_Node{x = x, y = y, g = g, f = g + ex * ex + ey * ey, parent = current}
			open[open_count] = i32(node_count)
			open_count += 1
			node_count += 1
		}
	}
	if !found do return -1
	path_count := 0
	cursor := current
	for cursor >= 0 { path_count += 1; cursor = nodes[cursor].parent }
	output_bytes := path_count * 16
	if output == nil || usize(capacity) < usize(output_bytes) do return -2
	offset := output_bytes
	cursor = current
	for cursor >= 0 {
		offset -= 16
		write_i64(output, usize(offset), i64(nodes[cursor].x))
		write_i64(output, usize(offset + 8), i64(nodes[cursor].y))
		cursor = nodes[cursor].parent
	}
	return i64(output_bytes)
}
