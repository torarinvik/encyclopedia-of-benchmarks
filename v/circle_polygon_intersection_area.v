module circle_polygon_intersection_area

import math

const max_coordinate = i64(32)
const invalid_result = -1.0e300

@[export: 'circle_polygon_intersection_area']
pub fn circle_polygon_intersection_area(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 10 || length > 37 { return invalid_result }
	n_value, cx, cy, radius_value := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }, unsafe { values[3] }
	if n_value < 3 || n_value > 16 { return invalid_result }
	if length != usize(4 + 2 * n_value) { return invalid_result }
	if cx < -max_coordinate || cx > max_coordinate || cy < -max_coordinate || cy > max_coordinate || radius_value < 1 || radius_value > max_coordinate { return invalid_result }
	n := int(n_value)
	for i in 0 .. n {
		x, y := unsafe { values[4 + 2 * i] }, unsafe { values[5 + 2 * i] }
		if x < -max_coordinate || x > max_coordinate || y < -max_coordinate || y > max_coordinate { return invalid_result }
	}
	for i in 0 .. n {
		next := (i + 1) % n
		x, y := unsafe { values[4 + 2 * i] }, unsafe { values[5 + 2 * i] }
		dx := unsafe { values[4 + 2 * next] } - x
		dy := unsafe { values[5 + 2 * next] } - y
		for j in 0 .. n {
			if j == i || j == next { continue }
			other_x, other_y := unsafe { values[4 + 2 * j] }, unsafe { values[5 + 2 * j] }
			if dx * (other_y - y) - dy * (other_x - x) <= 0 { return invalid_result }
		}
		if dx * (cy - y) - dy * (cx - x) <= 0 { return invalid_result }
	}

	radius := f64(radius_value)
	radius_squared := radius * radius
	mut doubled_area := f64(0)
	for i in 0 .. n {
		next := (i + 1) % n
		px, py := f64(unsafe { values[4 + 2 * i] } - cx), f64(unsafe { values[5 + 2 * i] } - cy)
		qx, qy := f64(unsafe { values[4 + 2 * next] } - cx), f64(unsafe { values[5 + 2 * next] } - cy)
		dx, dy := qx-px, qy-py
		edge_squared := dx*dx + dy*dy
		projection := px*dx + py*dy
		constant := px*px + py*py - radius_squared
		discriminant := projection*projection - edge_squared*constant
		full_angle := math.atan2(px*qy-py*qx, px*qx+py*qy)
		if discriminant <= 0 {
			doubled_area += radius_squared * full_angle
			continue
		}
		root := math.sqrt(discriminant)
		first, second := (-projection-root)/edge_squared, (-projection+root)/edge_squared
		if second < 0 || first > 1 {
			doubled_area += radius_squared * full_angle
			continue
		}
		mut start, stop := first, second
		if start < 0 { start = 0 }
		if stop > 1 { stop = 1 }
		ux, uy := px+start*dx, py+start*dy
		vx, vy := px+stop*dx, py+stop*dy
		first_angle := math.atan2(px*uy-py*ux, px*ux+py*uy)
		last_angle := math.atan2(vx*qy-vy*qx, vx*qx+vy*qy)
		doubled_area += radius_squared*(first_angle+last_angle) + ux*vy - uy*vx
	}
	return 0.5 * doubled_area
}
