package polygon_points

import "core:c"

MAX_INPUT_LENGTH :: 66
INVALID_RESULT :: i64(-1)

abs_i64 :: proc(value: i64) -> i64 {
	if value < 0 do return -value
	return value
}

gcd_i64 :: proc(a, b: i64) -> i64 {
	x, y := a, b
	for y != 0 {
		temp := y
		y = x % y
		x = temp
	}
	return x
}

cross :: proc(x1, y1, x2, y2: i64) -> i64 {
	return x1 * y2 - x2 * y1
}

@(export)
polygon_points :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	raw_n := values[0]
	if raw_n < 3 || raw_n > 32 || length != c.size_t(1+2*raw_n) do return INVALID_RESULT
	n := int(raw_n)
	for i := 0; i < 2*n; i += 1 {
		if values[1+i] < -1000 || values[1+i] > 1000 do return INVALID_RESULT
	}

	origin_x, origin_y := values[1], values[2]
	doubled_area := i64(0)
	for i := 2; i < n; i += 1 {
		x1 := values[1+2*i] - origin_x
		y1 := values[2+2*i] - origin_y
		x2 := values[1+2*(i-1)] - origin_x
		y2 := values[2+2*(i-1)] - origin_y
		doubled_area += cross(x1, y1, x2, y2)
	}
	area := abs_i64(doubled_area / 2)

	boundary := raw_n
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		dx := values[1+2*i] - values[1+2*next]
		dy := values[2+2*i] - values[2+2*next]
		boundary += abs_i64(gcd_i64(dx, dy)) - 1
	}
	return area + 1 - boundary/2
}
