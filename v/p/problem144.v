module problem144

import math

const invalid_result = -1.0e300
const max_reflections = 10000

struct RayPoint {
	x        f64
	y        f64
	gradient f64
}

fn is_close(left f64, right f64) bool {
	mut scale := math.abs(left)
	if math.abs(right) > scale { scale = math.abs(right) }
	return math.abs(left - right) <= 1.0e-9 * scale
}

fn next_point(point_x f64, point_y f64, incoming_gradient f64) RayPoint {
	normal_gradient := point_y / 4.0 / point_x
	s2 := 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient)
	c2 := (1.0 - normal_gradient * normal_gradient) / (1.0 + normal_gradient * normal_gradient)
	outgoing_gradient := (s2 - c2 * incoming_gradient) / (c2 + s2 * incoming_gradient)
	quadratic_term := outgoing_gradient * outgoing_gradient + 4.0
	line_offset := point_y - outgoing_gradient * point_x
	linear_term := 2.0 * outgoing_gradient * line_offset
	constant_term := line_offset * line_offset - 100.0
	root := math.sqrt(linear_term * linear_term - 4.0 * quadratic_term * constant_term)
	x_minus := (-linear_term - root) / (2.0 * quadratic_term)
	x_plus := (-linear_term + root) / (2.0 * quadratic_term)
	next_x := if is_close(x_plus, point_x) { x_minus } else { x_plus }
	return RayPoint{x: next_x, y: point_y + outgoing_gradient * (next_x - point_x), gradient: outgoing_gradient}
}

@[export: 'problem144']
pub fn problem144(first_x_coord f64, first_y_coord f64) f64 {
	if first_x_coord != first_x_coord || first_y_coord != first_y_coord ||
		first_x_coord < 1.0e-5 || first_x_coord > 5.0 || first_y_coord < -10.0 || first_y_coord > 0.0 {
		return invalid_result
	}
	ellipse_residual := 4.0 * first_x_coord * first_x_coord + first_y_coord * first_y_coord - 100.0
	if math.abs(ellipse_residual) > 1.0e-6 { return invalid_result }

	mut point_x := first_x_coord
	mut point_y := first_y_coord
	mut gradient := (10.1 - point_y) / (0.0 - point_x)
	mut reflections := 0
	for !(point_x >= -0.01 && point_x <= 0.01 && point_y > 0.0) {
		if reflections >= max_reflections { return invalid_result }
		next := next_point(point_x, point_y, gradient)
		if next.x != next.x || next.y != next.y { return invalid_result }
		point_x = next.x
		point_y = next.y
		gradient = next.gradient
		reflections++
	}
	return f64(reflections)
}
