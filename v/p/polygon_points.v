module main

const max_input_length = 66
const invalid_result = i64(-1)

fn abs_i64(value i64) i64 {
	if value < 0 { return -value }
	return value
}

fn gcd_i64(a i64, b i64) i64 {
	mut x := a
	mut y := b
	for y != 0 {
		temp := y
		y = x % y
		x = temp
	}
	return x
}

fn cross(x1 i64, y1 i64, x2 i64, y2 i64) i64 {
	return x1 * y2 - x2 * y1
}

@[export: 'polygon_points']
pub fn polygon_points(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_input_length { return invalid_result }
	raw_n := unsafe { values[0] }
	if raw_n < 3 || raw_n > 32 || length != usize(1 + 2 * raw_n) { return invalid_result }
	n := int(raw_n)
	unsafe {
		for i in 0 .. 2 * n {
			if values[1 + i] < -1000 || values[1 + i] > 1000 { return invalid_result }
		}
	}

	origin_x := unsafe { values[1] }
	origin_y := unsafe { values[2] }
	mut doubled_area := i64(0)
	unsafe {
		for i in 2 .. n {
			x1 := values[1 + 2 * i] - origin_x
			y1 := values[2 + 2 * i] - origin_y
			x2 := values[1 + 2 * (i - 1)] - origin_x
			y2 := values[2 + 2 * (i - 1)] - origin_y
			doubled_area += cross(x1, y1, x2, y2)
		}
	}
	area := abs_i64(doubled_area / 2)

	mut boundary := raw_n
	unsafe {
		for i in 0 .. n {
			next := (i + 1) % n
			dx := values[1 + 2 * i] - values[1 + 2 * next]
			dy := values[2 + 2 * i] - values[2 + 2 * next]
			boundary += abs_i64(gcd_i64(dx, dy)) - 1
		}
	}
	return area + 1 - boundary / 2
}
