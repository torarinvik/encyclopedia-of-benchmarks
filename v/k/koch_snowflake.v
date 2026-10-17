module koch_snowflake

const max_points = 29

struct Point32 {
mut:
	x f32
	y f32
}

@[export: 'koch_snowflake']
pub fn koch_snowflake(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 20 { return -1 }
	steps_value := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if steps_value != 0.0 && steps_value != 1.0 { return -1 }
	if count_value != 2.0 && count_value != 3.0 && count_value != 4.0 && count_value != 5.0 &&
		count_value != 6.0 && count_value != 7.0 && count_value != 8.0 { return -1 }
	steps := int(steps_value)
	point_count := int(count_value)
	if length != usize(2 + 2 * point_count) { return -1 }
	for i in 0 .. 2 * point_count {
		value := unsafe { input[i + 2] }
		if value != value || value < -1000.0 || value > 1000.0 { return -1 }
	}
	result_points := point_count
	if steps == 1 { result_points = 4 * (point_count - 1) + 1 }
	result_count := 2 * result_points
	if output == nil || output_capacity < usize(result_count) { return -2 }

	mut first := []Point32{len: max_points}
	mut second := []Point32{len: max_points}
	for i in 0 .. point_count {
		unsafe { first[i] = Point32{x: f32(input[2 + 2*i]), y: f32(input[3 + 2*i])} }
	}
	mut source := first
	mut destination := second
	mut source_count := point_count
	for _ in 0 .. steps {
		mut cursor := 0
		for i in 0 .. source_count - 1 {
			start := source[i]
			finish := source[i + 1]
			dx := finish.x - start.x
			dy := finish.y - start.y
			tx := dx / f32(3.0)
			ty := dy / f32(3.0)
			x1 := start.x + tx
			y1 := start.y + ty
			rx := f32(0.49999997) * tx - f32(0.86602545) * ty
			ry := f32(0.86602545) * tx + f32(0.49999997) * ty
			tx2 := (dx * f32(2.0)) / f32(3.0)
			ty2 := (dy * f32(2.0)) / f32(3.0)
			destination[cursor] = start
			cursor++
			destination[cursor] = Point32{x: x1, y: y1}
			cursor++
			destination[cursor] = Point32{x: x1 + rx, y: y1 + ry}
			cursor++
			destination[cursor] = Point32{x: start.x + tx2, y: start.y + ty2}
			cursor++
		}
		destination[cursor] = source[source_count - 1]
		cursor++
		source_count = cursor
		temp := source
		source = destination
		destination = temp
	}
	for i in 0 .. result_points {
		unsafe { output[2*i] = f64(source[i].x); output[2*i+1] = f64(source[i].y) }
	}
	return i64(result_count)
}
