package line_intersection

import "core:c"

Point :: struct { x, y: i64 }
same :: proc(a, b: Point) -> bool { return a.x == b.x && a.y == b.y }
cross :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
on_segment :: proc(a, b, p: Point) -> bool {
	return cross(a, b, p) == 0 && min(a.x, b.x) <= p.x && p.x <= max(a.x, b.x) &&
		min(a.y, b.y) <= p.y && p.y <= max(a.y, b.y)
}
write_point :: proc(output: [^]u8, capacity: c.size_t, x, y: f64) -> i64 {
	if output == nil || capacity < 16 do return -2
	x_bits := transmute(u64)x
	y_bits := transmute(u64)y
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(x_bits >> u64(8 * byte))
		output[8 + byte] = u8(y_bits >> u64(8 * byte))
	}
	return 1
}

@(export)
line_intersection :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 9 || values == nil do return -1
	for index := 0; index < 8; index += 1 { if values[index] < -10000 || values[index] > 10000 do return -1 }
	if values[8] != 0 && values[8] != 1 do return -1
	p1 := Point{x = values[0], y = values[1]}
	p2 := Point{x = values[2], y = values[3]}
	q1 := Point{x = values[4], y = values[5]}
	q2 := Point{x = values[6], y = values[7]}
	segments := values[8] == 1
	p_point, q_point := same(p1, p2), same(q1, q2)
	if !segments && (p_point || q_point) do return -1
	if segments && p_point && q_point {
		if same(p1, q1) do return write_point(output, output_capacity, f64(p1.x), f64(p1.y))
		return 0
	}
	if segments && p_point {
		if on_segment(q1, q2, p1) do return write_point(output, output_capacity, f64(p1.x), f64(p1.y))
		return 0
	}
	if segments && q_point {
		if on_segment(p1, p2, q1) do return write_point(output, output_capacity, f64(q1.x), f64(q1.y))
		return 0
	}
	denominator := (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x)
	if denominator == 0 do return 0
	determinant_p := p1.x * p2.y - p1.y * p2.x
	determinant_q := q1.x * q2.y - q1.y * q2.x
	numerator_x := determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q
	numerator_y := determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q
	if segments {
		den := if denominator < 0 { -denominator } else { denominator }
		x := if denominator < 0 { -numerator_x } else { numerator_x }
		y := if denominator < 0 { -numerator_y } else { numerator_y }
		min_x := max(min(p1.x, p2.x), min(q1.x, q2.x))
		max_x := min(max(p1.x, p2.x), max(q1.x, q2.x))
		min_y := max(min(p1.y, p2.y), min(q1.y, q2.y))
		max_y := min(max(p1.y, p2.y), max(q1.y, q2.y))
		if x < min_x * den || x > max_x * den || y < min_y * den || y > max_y * den do return 0
		return write_point(output, output_capacity, f64(x) / f64(den), f64(y) / f64(den))
	}
	return write_point(output, output_capacity, f64(numerator_x) / f64(denominator),
		f64(numerator_y) / f64(denominator))
}
