package olden_perimeter

import "core:c"

visit_cells :: proc(x, y, span, grid, edge: i64) -> i64 {
	if span == 1 {
		perimeter: i64 = 0
		if x == 0 do perimeter += edge
		if x + 1 == grid do perimeter += edge
		if y == 0 do perimeter += edge
		if y + 1 == grid do perimeter += edge
		return perimeter
	}

	half := span / 2
	return visit_cells(x, y, half, grid, edge) +
		visit_cells(x + half, y, half, grid, edge) +
		visit_cells(x, y + half, half, grid, edge) +
		visit_cells(x + half, y + half, half, grid, edge)
}

@(export)
olden_perimeter :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	level := values[0]
	if level < 9 || level > 11 do return -1
	grid: i64 = 1
	for i: i64 = 0; i < level; i += 1 {
		grid *= 2
	}
	edge := i64(4096) / grid
	return visit_cells(0, 0, grid, grid, edge)
}
