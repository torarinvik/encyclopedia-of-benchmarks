package cohen_sutherland

import "core:c"

INVALID_RESULT :: -1.0e300
SCALE :: 1_000_000.0
MAX_COORDINATE_MICRO :: i64(1_000_000_000)
INSIDE :: 0
LEFT :: 1
RIGHT :: 2
BOTTOM :: 4
TOP :: 8

region_code :: proc(x, y, x_min, y_min, x_max, y_max: f64) -> i32 {
	code := i32(INSIDE)
	if x < x_min do code |= i32(LEFT)
	else if x > x_max do code |= i32(RIGHT)
	if y < y_min do code |= i32(BOTTOM)
	else if y > y_max do code |= i32(TOP)
	return code
}

@(export)
cohen_sutherland :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 9 do return INVALID_RESULT
	selector := values[0]
	if selector < 0 || selector > 4 do return INVALID_RESULT
	for i in 1..<9 {
		if values[i] < -MAX_COORDINATE_MICRO || values[i] > MAX_COORDINATE_MICRO do return INVALID_RESULT
	}
	x_min := f64(values[1]) / SCALE
	y_min := f64(values[2]) / SCALE
	x_max := f64(values[3]) / SCALE
	y_max := f64(values[4]) / SCALE
	if x_min >= x_max || y_min >= y_max do return INVALID_RESULT
	x1 := f64(values[5]) / SCALE
	y1 := f64(values[6]) / SCALE
	x2 := f64(values[7]) / SCALE
	y2 := f64(values[8]) / SCALE
	code1 := region_code(x1, y1, x_min, y_min, x_max, y_max)
	code2 := region_code(x2, y2, x_min, y_min, x_max, y_max)
	accepted := false
	for {
		if code1 == INSIDE && code2 == INSIDE {
			accepted = true
			break
		}
		if (code1 & code2) != 0 do break
		code_out := if code1 != INSIDE { code1 } else { code2 }
		x: f64
		y: f64
		if (code_out & TOP) != 0 {
			x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
			y = y_max
		} else if (code_out & BOTTOM) != 0 {
			x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
			y = y_min
		} else if (code_out & RIGHT) != 0 {
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
	if selector == 4 {
		if accepted do return 1.0
		return 0.0
	}
	if !accepted do return INVALID_RESULT
	switch selector {
	case 0: return x1
	case 1: return y1
	case 2: return x2
	case: return y2
	}
}
