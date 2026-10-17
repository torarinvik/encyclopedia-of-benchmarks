module affine_image_rotation

const max_dimension = 8
const max_cells = 64
const max_input_length = 79

struct AxisSolution {
	first i64
	second i64
	translation i64
	valid bool
}

fn solve_axis(x [3]i64, y [3]i64, target [3]i64) AxisSolution {
	determinant := x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1])
	if determinant == 0 { return AxisSolution{} }
	first := target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1])
	second := x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1])
	translation := x[0] * (y[1] * target[2] - y[2] * target[1]) + x[1] * (y[2] * target[0] - y[0] * target[2]) + x[2] * (y[0] * target[1] - y[1] * target[0])
	if first % determinant != 0 || second % determinant != 0 || translation % determinant != 0 { return AxisSolution{} }
	return AxisSolution{first: first / determinant, second: second / determinant, translation: translation / determinant, valid: true}
}

@[export: 'affine_image_rotation']
pub fn affine_image_rotation(input &i32, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	unsafe {
		rows_value, cols_value := input[0], input[1]
		if rows_value < 1 || rows_value > max_dimension || cols_value < 1 || cols_value > max_dimension { return -1 }
		rows, cols := int(rows_value), int(cols_value)
		cells := rows * cols
		if length != usize(14 + cells) { return -1 }
		mut pixels := [max_cells]u8{}
		for i in 0 .. cells { if input[2 + i] < 0 || input[2 + i] > 255 { return -1 }; pixels[i] = u8(input[2 + i]) }
		point_offset := 2 + cells
		mut sx := [3]i64{}
		mut sy := [3]i64{}
		mut dx := [3]i64{}
		mut dy := [3]i64{}
		for i in 0 .. 3 {
			sx[i], sy[i] = i64(input[point_offset + 2 * i]), i64(input[point_offset + 2 * i + 1])
			dx[i], dy[i] = i64(input[point_offset + 6 + 2 * i]), i64(input[point_offset + 7 + 2 * i])
			if sx[i] < -16 || sx[i] > 16 || sy[i] < -16 || sy[i] > 16 || dx[i] < -16 || dx[i] > 16 || dy[i] < -16 || dy[i] > 16 { return -1 }
		}
		x_axis, y_axis := solve_axis(sx, sy, dx), solve_axis(sx, sy, dy)
		if !x_axis.valid || !y_axis.valid { return -1 }
		a, b, tx := x_axis.first, x_axis.second, x_axis.translation
		c, d, ty := y_axis.first, y_axis.second, y_axis.translation
		if a < -2 || a > 2 || b < -2 || b > 2 || c < -2 || c > 2 || d < -2 || d > 2 || tx < -16 || tx > 16 || ty < -16 || ty > 16 { return -1 }
		determinant := a * d - b * c
		if determinant != -1 && determinant != 1 { return -1 }
		for i in 0 .. 3 { if dx[i] != a * sx[i] + b * sy[i] + tx || dy[i] != c * sx[i] + d * sy[i] + ty { return -1 } }
		if unsafe { output == nil } || capacity < usize(cells) { return -2 }
		mut written := 0
		for y in 0 .. cols {
			for x in 0 .. rows {
				px, py := i64(x) - tx, i64(y) - ty
				source_x, source_y := (d * px - b * py) / determinant, (-c * px + a * py) / determinant
				if source_x >= 0 && source_x < i64(cols) && source_y >= 0 && source_y < i64(rows) { output[written] = pixels[int(source_y) * cols + int(source_x)] } else { output[written] = 0 }
				written++
			}
		}
		return i64(cells)
	}
}
