module ptrdist_yacr2_maze1_dogleg

// Clean-room bounded YACR2 Maze1 profile; rights status is documented in package README.
const max_columns = 16
const max_tracks = 16

fn free_vertical(v &i64, plane int, columns int, x int, y1 int, y2 int) bool {
	low := if y1 < y2 { y1 } else { y2 }
	high := if y1 < y2 { y2 } else { y1 }
	for y := low; y <= high; y++ {
		if unsafe { v[plane + y * columns + x - 1] } != 0 { return false }
	}
	return true
}
fn free_horizontal(v &i64, plane int, columns int, x1 int, x2 int, y int) bool {
	low := if x1 < x2 { x1 } else { x2 }
	high := if x1 < x2 { x2 } else { x1 }
	for x := low; x <= high; x++ {
		if unsafe { v[plane + y * columns + x - 1] } != 0 { return false }
	}
	return true
}
fn try_dogleg(v &i64, plane int, vcv int, columns int, tracks int, column int, bottom int, top int, dx int, upper bool) bool {
	neighbor := column + dx
	if upper {
		jog := bottom - 1
		return free_vertical(v, plane, columns, column, tracks + 1, bottom) &&
			free_vertical(v, plane, columns, column, 0, jog) &&
			free_horizontal(v, plane, columns, column, neighbor, jog) &&
			free_vertical(v, plane, columns, neighbor, jog, top) && unsafe { v[vcv + neighbor - 1] == 0 }
	}
	jog := top + 1
	return free_vertical(v, plane, columns, column, 0, top) &&
		free_vertical(v, plane, columns, column, tracks + 1, jog) &&
		free_horizontal(v, plane, columns, column, neighbor, jog) &&
		free_vertical(v, plane, columns, neighbor, jog, bottom) && unsafe { v[vcv + neighbor - 1] == 0 }
}

@[export: 'ptrdist_yacr2_maze1_dogleg']
pub fn ptrdist_yacr2_maze1_dogleg(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_columns || input[1] < 2 || input[1] > max_tracks { return -1 }
		columns, tracks := int(input[0]), int(input[1])
		if input[2] < 1 || input[2] > input[0] || input[3] < 1 || input[3] >= input[4] || input[4] > input[1] { return -1 }
		column, bottom, top := int(input[2]), int(input[3]), int(input[4])
		if length != usize(5 + columns + columns * (tracks + 2)) { return -1 }
		vcv, plane := 5, 5 + columns
		for i := vcv; i < plane; i++ { if input[i] != 0 && input[i] != 1 { return -1 } }
		for i := plane; i < int(length); i++ { if input[i] != 0 && input[i] != 1 { return -1 } }
		if bottom > 1 && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, true) { return 1 }
		if bottom > 1 && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, true) { return 2 }
		if top < tracks && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, false) { return 3 }
		if top < tracks && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, false) { return 4 }
		return 0
	}
}
