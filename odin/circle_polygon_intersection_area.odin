package circle_polygon_intersection_area

import "core:c"
import "core:math"

MAX_INPUT :: c.size_t(37)
MAX_COORDINATE :: i64(32)
INVALID_RESULT :: -1.0e300

@(export)
circle_polygon_intersection_area :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 10 || length > MAX_INPUT do return INVALID_RESULT
	n_value, cx, cy, radius_value := values[0], values[1], values[2], values[3]
	if n_value < 3 || n_value > 16 do return INVALID_RESULT
	if length != c.size_t(4 + 2 * n_value) do return INVALID_RESULT
	if cx < -MAX_COORDINATE || cx > MAX_COORDINATE || cy < -MAX_COORDINATE || cy > MAX_COORDINATE ||
		radius_value < 1 || radius_value > MAX_COORDINATE do return INVALID_RESULT
	n := int(n_value)
	for i := 0; i < n; i += 1 {
		x, y := values[4+2*i], values[5+2*i]
		if x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE do return INVALID_RESULT
	}
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		x, y := values[4+2*i], values[5+2*i]
		dx, dy := values[4+2*next]-x, values[5+2*next]-y
		for j := 0; j < n; j += 1 {
			if j == i || j == next do continue
			if dx*(values[5+2*j]-y)-dy*(values[4+2*j]-x) <= 0 do return INVALID_RESULT
		}
		if dx*(cy-y)-dy*(cx-x) <= 0 do return INVALID_RESULT
	}

	radius := f64(radius_value)
	radius_squared := radius * radius
	doubled_area := f64(0)
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		px, py := f64(values[4+2*i]-cx), f64(values[5+2*i]-cy)
		qx, qy := f64(values[4+2*next]-cx), f64(values[5+2*next]-cy)
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
		start := first; if start < 0 { start = 0 }
		stop := second; if stop > 1 { stop = 1 }
		ux, uy := px+start*dx, py+start*dy
		vx, vy := px+stop*dx, py+stop*dy
		first_angle := math.atan2(px*uy-py*ux, px*ux+py*uy)
		last_angle := math.atan2(vx*qy-vy*qx, vx*qx+vy*qy)
		doubled_area += radius_squared*(first_angle+last_angle) + ux*vy - uy*vx
	}
	return 0.5 * doubled_area
}
