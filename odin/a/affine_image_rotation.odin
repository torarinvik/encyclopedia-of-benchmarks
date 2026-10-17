package affine_image_rotation

import "core:c"

MAX_DIMENSION :: 8
MAX_CELLS :: 64
MAX_INPUT_LENGTH :: 79

Axis_Solution :: struct { first, second, translation: i64, valid: bool }

solve_axis :: proc "contextless" (x, y, target: [3]i64) -> Axis_Solution {
	determinant := x[0]*(y[1]-y[2]) + x[1]*(y[2]-y[0]) + x[2]*(y[0]-y[1])
	if determinant == 0 do return {}
	first := target[0]*(y[1]-y[2]) + target[1]*(y[2]-y[0]) + target[2]*(y[0]-y[1])
	second := x[0]*(target[1]-target[2]) + x[1]*(target[2]-target[0]) + x[2]*(target[0]-target[1])
	translation := x[0]*(y[1]*target[2]-y[2]*target[1]) + x[1]*(y[2]*target[0]-y[0]*target[2]) + x[2]*(y[0]*target[1]-y[1]*target[0])
	if first % determinant != 0 || second % determinant != 0 || translation % determinant != 0 do return {}
	return {first=first/determinant, second=second/determinant, translation=translation/determinant, valid=true}
}

@(export)
affine_image_rotation :: proc "c" (input: [^]i32, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	rows_value, cols_value := input[0], input[1]
	if rows_value < 1 || rows_value > MAX_DIMENSION || cols_value < 1 || cols_value > MAX_DIMENSION do return -1
	rows, cols := int(rows_value), int(cols_value)
	cells := rows * cols
	if int(length) != 14 + cells do return -1
	pixels: [MAX_CELLS]u8
	for i := 0; i < cells; i += 1 { if input[2+i] < 0 || input[2+i] > 255 do return -1; pixels[i] = u8(input[2+i]) }
	point_offset := 2 + cells
	sx, sy, dx, dy: [3]i64
	for i := 0; i < 3; i += 1 {
		sx[i], sy[i] = i64(input[point_offset+2*i]), i64(input[point_offset+2*i+1])
		dx[i], dy[i] = i64(input[point_offset+6+2*i]), i64(input[point_offset+7+2*i])
		if sx[i] < -16 || sx[i] > 16 || sy[i] < -16 || sy[i] > 16 || dx[i] < -16 || dx[i] > 16 || dy[i] < -16 || dy[i] > 16 do return -1
	}
	x_axis, y_axis := solve_axis(sx, sy, dx), solve_axis(sx, sy, dy)
	if !x_axis.valid || !y_axis.valid do return -1
	a, b, tx := x_axis.first, x_axis.second, x_axis.translation
	cv, d, ty := y_axis.first, y_axis.second, y_axis.translation
	if a < -2 || a > 2 || b < -2 || b > 2 || cv < -2 || cv > 2 || d < -2 || d > 2 || tx < -16 || tx > 16 || ty < -16 || ty > 16 do return -1
	determinant := a*d-b*cv
	if determinant != -1 && determinant != 1 do return -1
	for i := 0; i < 3; i += 1 { if dx[i] != a*sx[i]+b*sy[i]+tx || dy[i] != cv*sx[i]+d*sy[i]+ty do return -1 }
	if output == nil || capacity < c.size_t(cells) do return -2
	written := 0
	for y := 0; y < cols; y += 1 {
		for x := 0; x < rows; x += 1 {
			px, py := i64(x)-tx, i64(y)-ty
		source_x, source_y := (d*px-b*py)/determinant, (-cv*px+a*py)/determinant
			if source_x >= 0 && source_x < i64(cols) && source_y >= 0 && source_y < i64(rows) do output[written] = pixels[int(source_y)*cols+int(source_x)]
			else do output[written] = 0
			written += 1
		}
	}
	return i64(cells)
}
