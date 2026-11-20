module bricks_falling_when_hit_reverse_dsu

const max_cells = 64
const max_hits = 16
const max_input_length = 100

fn find_root(mut parent &i32, vertex_value int) int {
	mut vertex := vertex_value
	unsafe {
		for parent[vertex] != vertex {
			parent[vertex] = parent[parent[vertex]]
			vertex = parent[vertex]
		}
	}
	return vertex
}

fn unite(mut parent &i32, mut component_size &i32, left int, right int) {
	mut a := find_root(mut parent, left)
	mut b := find_root(mut parent, right)
	if a == b { return }
	unsafe {
		if component_size[a] < component_size[b] {
			temporary := a
			a = b
			b = temporary
		}
		parent[b] = a
		component_size[a] += component_size[b]
	}
}

fn build_dsu(grid &u8, rows int, columns int, mut parent &i32, mut component_size &i32) {
	cells := rows * columns
	unsafe {
		for cell in 0 .. cells {
			parent[cell] = cell
			component_size[cell] = int(grid[cell])
		}
		parent[cells] = cells
		component_size[cells] = 0
		for cell in 0 .. cells {
			if grid[cell] == 0 { continue }
			row := cell / columns
			column := cell % columns
			if row == 0 { unite(mut parent, mut component_size, cell, cells) }
			if row > 0 && grid[cell - columns] != 0 { unite(mut parent, mut component_size, cell, cell - columns) }
			if column > 0 && grid[cell - 1] != 0 { unite(mut parent, mut component_size, cell, cell - 1) }
		}
	}
}

fn put_i64_le(mut output &u8, offset int, value i32) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'bricks_falling_when_hit_reverse_dsu']
pub fn bricks_falling_when_hit_reverse_dsu(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	row_value := unsafe { input[0] }
	column_value := unsafe { input[1] }
	hit_value := unsafe { input[2] }
	if row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 || hit_value < 0 || hit_value > max_hits { return -1 }
	rows := int(row_value)
	columns := int(column_value)
	cells := rows * columns
	hits := int(hit_value)
	if hits > cells || length != usize(3 + cells + 2 * hits) { return -1 }

	mut grid := [max_cells]u8{}
	mut parent := [max_cells + 1]i32{}
	mut component_size := [max_cells + 1]i32{}
	unsafe {
		for cell in 0 .. cells {
			value := input[3 + cell]
			if value != 0 && value != 1 { return -1 }
			grid[cell] = u8(value)
		}
	}
	hit_start := 3 + cells
	unsafe {
		for index in 0 .. hits {
			row := input[hit_start + 2 * index]
			column := input[hit_start + 2 * index + 1]
			if row < 0 || row >= row_value || column < 0 || column >= column_value { return -1 }
			for previous in 0 .. index {
				if input[hit_start + 2 * previous] == row && input[hit_start + 2 * previous + 1] == column { return -1 }
			}
		}
	}

	unsafe { build_dsu(&grid[0], rows, columns, mut parent[0], mut component_size[0]) }
	roof_root := find_root(mut parent[0], cells)
	unsafe {
		for cell in 0 .. cells {
			if grid[cell] != 0 && find_root(mut parent[0], cell) != roof_root { return -1 }
		}
	}

	required := hits * 8
	if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
	if hits == 0 { return 0 }
	unsafe {
		for index in 0 .. hits {
			row := int(input[hit_start + 2 * index])
			column := int(input[hit_start + 2 * index + 1])
			grid[row * columns + column] = 0
		}
		build_dsu(&grid[0], rows, columns, mut parent[0], mut component_size[0])
	}

	for reverse in 0 .. hits {
		index := hits - 1 - reverse
		row := int(unsafe { input[hit_start + 2 * index] })
		column := int(unsafe { input[hit_start + 2 * index + 1] })
		cell := row * columns + column
		if unsafe { input[3 + cell] == 0 } {
			put_i64_le(mut output, index * 8, 0)
			continue
		}
		before := unsafe { component_size[find_root(mut parent[0], cells)] }
		unsafe {
			grid[cell] = 1
			parent[cell] = cell
			component_size[cell] = 1
			if row == 0 { unite(mut parent[0], mut component_size[0], cell, cells) }
			if row > 0 && grid[cell - columns] != 0 { unite(mut parent[0], mut component_size[0], cell, cell - columns) }
			if row + 1 < rows && grid[cell + columns] != 0 { unite(mut parent[0], mut component_size[0], cell, cell + columns) }
			if column > 0 && grid[cell - 1] != 0 { unite(mut parent[0], mut component_size[0], cell, cell - 1) }
			if column + 1 < columns && grid[cell + 1] != 0 { unite(mut parent[0], mut component_size[0], cell, cell + 1) }
		}
		after := unsafe { component_size[find_root(mut parent[0], cells)] }
		fallen := if after > before + 1 { after - before - 1 } else { 0 }
		put_i64_le(mut output, index * 8, i32(fallen))
	}
	return i64(required)
}
