module cohen_sutherland

const invalid_result = -1.0e300
const scale = 1000000.0
const max_coordinate_micro = i64(1000000000)
const inside = 0
const left = 1
const right = 2
const bottom = 4
const top = 8

fn region_code(x f64, y f64, x_min f64, y_min f64, x_max f64, y_max f64) int {
	mut code := inside
	if x < x_min { code |= left } else if x > x_max { code |= right }
	if y < y_min { code |= bottom } else if y > y_max { code |= top }
	return code
}

@[export: 'cohen_sutherland']
pub fn cohen_sutherland(values &i64, length usize) f64 {
	if values == nil || length != 9 { return invalid_result }
	selector := unsafe { values[0] }
	if selector < 0 || selector > 4 { return invalid_result }
	for i in 1 .. 9 {
		value := unsafe { values[i] }
		if value < -max_coordinate_micro || value > max_coordinate_micro { return invalid_result }
	}
	x_min := f64(unsafe { values[1] }) / scale
	y_min := f64(unsafe { values[2] }) / scale
	x_max := f64(unsafe { values[3] }) / scale
	y_max := f64(unsafe { values[4] }) / scale
	if x_min >= x_max || y_min >= y_max { return invalid_result }
	mut x1 := f64(unsafe { values[5] }) / scale
	mut y1 := f64(unsafe { values[6] }) / scale
	mut x2 := f64(unsafe { values[7] }) / scale
	mut y2 := f64(unsafe { values[8] }) / scale
	mut code1 := region_code(x1, y1, x_min, y_min, x_max, y_max)
	mut code2 := region_code(x2, y2, x_min, y_min, x_max, y_max)
	mut accepted := false
	for {
		if code1 == inside && code2 == inside { accepted = true; break }
		if (code1 & code2) != 0 { break }
		code_out := if code1 != inside { code1 } else { code2 }
		mut x := f64(0)
		mut y := f64(0)
		if (code_out & top) != 0 {
			x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
			y = y_max
		} else if (code_out & bottom) != 0 {
			x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
			y = y_min
		} else if (code_out & right) != 0 {
			y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
			x = x_max
		} else {
			y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
			x = x_min
		}
		if code_out == code1 {
			x1 = x; y1 = y
			code1 = region_code(x1, y1, x_min, y_min, x_max, y_max)
		} else {
			x2 = x; y2 = y
			code2 = region_code(x2, y2, x_min, y_min, x_max, y_max)
		}
	}
	if selector == 4 { return if accepted { 1.0 } else { 0.0 } }
	if !accepted { return invalid_result }
	return match selector { 0 { x1 } 1 { y1 } 2 { x2 } else { y2 } }
}
