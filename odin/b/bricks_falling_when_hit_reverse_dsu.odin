package bricks_falling_when_hit_reverse_dsu

import "core:c"

MAX_CELLS :: 64
MAX_HITS :: 16
MAX_INPUT_LENGTH :: 100

find_root :: proc(parent: [^]i32, vertex_value: int) -> int {
	vertex := vertex_value
	for int(parent[vertex]) != vertex {
		parent[vertex] = parent[int(parent[vertex])]
		vertex = int(parent[vertex])
	}
	return vertex
}

unite :: proc(parent: [^]i32, component_size: [^]i32, left: int, right: int) {
	a := find_root(parent, left)
	b := find_root(parent, right)
	if a == b do return
	if component_size[a] < component_size[b] { temporary := a; a = b; b = temporary }
	parent[b] = i32(a)
	component_size[a] += component_size[b]
}

build_dsu :: proc(grid: [^]u8, rows: int, columns: int,
	parent: [^]i32, component_size: [^]i32) {
	cells := rows * columns
	for cell := 0; cell < cells; cell += 1 {
		parent[cell] = i32(cell)
		component_size[cell] = i32(grid[cell])
	}
	parent[cells] = i32(cells)
	component_size[cells] = 0
	for cell := 0; cell < cells; cell += 1 {
		if grid[cell] == 0 do continue
		row := cell / columns
		column := cell % columns
		if row == 0 { unite(parent, component_size, cell, cells) }
		if row > 0 && grid[cell-columns] != 0 { unite(parent, component_size, cell, cell-columns) }
		if column > 0 && grid[cell-1] != 0 { unite(parent, component_size, cell, cell-1) }
	}
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
bricks_falling_when_hit_reverse_dsu :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	row_value, column_value, hit_value := input[0], input[1], input[2]
	if row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 || hit_value < 0 || hit_value > MAX_HITS do return -1
	rows, columns := int(row_value), int(column_value)
	cells := rows * columns
	hits := int(hit_value)
	if hits > cells || int(length) != 3+cells+2*hits do return -1

	grid: [MAX_CELLS]u8
	parent: [MAX_CELLS+1]i32
	component_size: [MAX_CELLS+1]i32
	for cell := 0; cell < cells; cell += 1 {
		value := input[3+cell]
		if value != 0 && value != 1 do return -1
		grid[cell] = u8(value)
	}
	hit_start := 3+cells
	for index := 0; index < hits; index += 1 {
		row, column := input[hit_start+2*index], input[hit_start+2*index+1]
		if row < 0 || row >= row_value || column < 0 || column >= column_value do return -1
		for previous := 0; previous < index; previous += 1 {
			if input[hit_start+2*previous] == row && input[hit_start+2*previous+1] == column do return -1
		}
	}

	build_dsu(&grid[0], rows, columns, &parent[0], &component_size[0])
	roof_root := find_root(&parent[0], cells)
	for cell := 0; cell < cells; cell += 1 {
		if grid[cell] != 0 && find_root(&parent[0], cell) != roof_root do return -1
	}

	required := hits*8
	if int(capacity) < required || (required > 0 && output == nil) do return -2
	if hits == 0 do return 0
	for index := 0; index < hits; index += 1 {
		row, column := int(input[hit_start+2*index]), int(input[hit_start+2*index+1])
		grid[row*columns+column] = 0
	}
	build_dsu(&grid[0], rows, columns, &parent[0], &component_size[0])

	for reverse := hits; reverse > 0; reverse -= 1 {
		index := reverse-1
		row, column := int(input[hit_start+2*index]), int(input[hit_start+2*index+1])
		cell := row*columns+column
		if input[3+cell] == 0 { put_i64_le(output, index*8, 0); continue }
		before := component_size[find_root(&parent[0], cells)]
		grid[cell] = 1
		parent[cell] = i32(cell)
		component_size[cell] = 1
		if row == 0 { unite(&parent[0], &component_size[0], cell, cells) }
		if row > 0 && grid[cell-columns] != 0 { unite(&parent[0], &component_size[0], cell, cell-columns) }
		if row+1 < rows && grid[cell+columns] != 0 { unite(&parent[0], &component_size[0], cell, cell+columns) }
		if column > 0 && grid[cell-1] != 0 { unite(&parent[0], &component_size[0], cell, cell-1) }
		if column+1 < columns && grid[cell+1] != 0 { unite(&parent[0], &component_size[0], cell, cell+1) }
		after := component_size[find_root(&parent[0], cells)]
		fallen := if after > before+1 { after-before-1 } else { 0 }
		put_i64_le(output, index*8, fallen)
	}
	return i64(required)
}
