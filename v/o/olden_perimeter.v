module olden_perimeter

fn visit_cells(x i64, y i64, span i64, grid i64, edge i64) i64 {
	if span == 1 {
		mut perimeter := i64(0)
		if x == 0 { perimeter += edge }
		if x + 1 == grid { perimeter += edge }
		if y == 0 { perimeter += edge }
		if y + 1 == grid { perimeter += edge }
		return perimeter
	}
	half := span / 2
	return visit_cells(x, y, half, grid, edge) +
		visit_cells(x + half, y, half, grid, edge) +
		visit_cells(x, y + half, half, grid, edge) +
		visit_cells(x + half, y + half, half, grid, edge)
}

@[export: 'olden_perimeter']
pub fn olden_perimeter(values &i64, length usize) i64 {
	if length != 1 || unsafe { values == nil } { return -1 }
	unsafe {
		level := values[0]
		if level < 9 || level > 11 { return -1 }
		mut grid := i64(1)
		for _ in 0 .. level { grid *= 2 }
		edge := i64(4096) / grid
		return visit_cells(0, 0, grid, grid, edge)
	}
}
