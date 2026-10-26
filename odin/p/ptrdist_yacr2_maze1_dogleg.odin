package ptrdist_yacr2_maze1_dogleg

import "core:c"

// Clean-room bounded YACR2 Maze1 profile; rights status is documented in package README.
MAX_COLUMNS :: 16
MAX_TRACKS :: 16

free_vertical :: proc(v: [^]i64, plane, columns, x, y1, y2: int) -> bool {
	low, high := min(y1, y2), max(y1, y2)
	for y in low ..= high do if v[plane + y*columns + x-1] != 0 do return false
	return true
}
free_horizontal :: proc(v: [^]i64, plane, columns, x1, x2, y: int) -> bool {
	low, high := min(x1, x2), max(x1, x2)
	for x in low ..= high do if v[plane + y*columns + x-1] != 0 do return false
	return true
}
try_dogleg :: proc(v: [^]i64, plane, vcv, columns, tracks, column, bottom, top, dx: int, upper: bool) -> bool {
	neighbor := column + dx
	if upper {
		jog := bottom - 1
		return free_vertical(v, plane, columns, column, tracks+1, bottom) &&
			free_vertical(v, plane, columns, column, 0, jog) &&
			free_horizontal(v, plane, columns, column, neighbor, jog) &&
			free_vertical(v, plane, columns, neighbor, jog, top) && v[vcv+neighbor-1] == 0
	}
	jog := top + 1
	return free_vertical(v, plane, columns, column, 0, top) &&
		free_vertical(v, plane, columns, column, tracks+1, jog) &&
		free_horizontal(v, plane, columns, column, neighbor, jog) &&
		free_vertical(v, plane, columns, neighbor, jog, bottom) && v[vcv+neighbor-1] == 0
}

@(export)
ptrdist_yacr2_maze1_dogleg :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 do return -1
	if input[0] < 2 || input[0] > MAX_COLUMNS || input[1] < 2 || input[1] > MAX_TRACKS do return -1
	columns, tracks := int(input[0]), int(input[1])
	if input[2] < 1 || input[2] > input[0] || input[3] < 1 || input[3] >= input[4] || input[4] > input[1] do return -1
	column, bottom, top := int(input[2]), int(input[3]), int(input[4])
	if length != c.size_t(5 + columns + columns*(tracks+2)) do return -1
	vcv, plane := 5, 5+columns
	for i in vcv ..< plane do if input[i] != 0 && input[i] != 1 do return -1
	for i in plane ..< int(length) do if input[i] != 0 && input[i] != 1 do return -1

	if bottom > 1 && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, true) do return 1
	if bottom > 1 && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, true) do return 2
	if top < tracks && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, false) do return 3
	if top < tracks && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, false) do return 4
	return 0
}
