module line_intersection

import math

struct Point {
	x i64
	y i64
}

fn same(a Point, b Point) bool { return a.x == b.x && a.y == b.y }

fn on_segment(a Point, b Point, p Point) bool {
	return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x) == 0 &&
		p.x >= min(a.x, b.x) && p.x <= max(a.x, b.x) &&
		p.y >= min(a.y, b.y) && p.y <= max(a.y, b.y)
}

fn write_f64(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn write_point(mut output &u8, capacity usize, x f64, y f64) i64 {
	if unsafe { output == nil } || capacity < 16 { return -2 }
	write_f64(mut output, 0, x)
	write_f64(mut output, 8, y)
	return 1
}

// Return one for a unique point, zero for no unique point, or a negative error.
@[export: 'line_intersection']
pub fn line_intersection(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 9 || unsafe { values == nil } { return -1 }
	for index in 0 .. 8 {
		if values[index] < -10000 || values[index] > 10000 { return -1 }
	}
	if values[8] != 0 && values[8] != 1 { return -1 }
	p1 := Point{values[0], values[1]}
	p2 := Point{values[2], values[3]}
	q1 := Point{values[4], values[5]}
	q2 := Point{values[6], values[7]}
	segments := values[8] == 1
	p_point := same(p1, p2)
	q_point := same(q1, q2)
	if !segments && (p_point || q_point) { return -1 }
	if segments && p_point && q_point {
		return if same(p1, q1) { write_point(mut output, output_capacity, f64(p1.x), f64(p1.y)) } else { i64(0) }
	}
	if segments && p_point {
		return if on_segment(q1, q2, p1) { write_point(mut output, output_capacity, f64(p1.x), f64(p1.y)) } else { i64(0) }
	}
	if segments && q_point {
		return if on_segment(p1, p2, q1) { write_point(mut output, output_capacity, f64(q1.x), f64(q1.y)) } else { i64(0) }
	}
	denominator := (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x)
	if denominator == 0 { return 0 }
	determinant_p := p1.x * p2.y - p1.y * p2.x
	determinant_q := q1.x * q2.y - q1.y * q2.x
	numerator_x := determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q
	numerator_y := determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q
	if segments {
		positive_denominator := if denominator < 0 { -denominator } else { denominator }
		positive_x := if denominator < 0 { -numerator_x } else { numerator_x }
		positive_y := if denominator < 0 { -numerator_y } else { numerator_y }
		min_x := max(min(p1.x, p2.x), min(q1.x, q2.x))
		max_x := min(max(p1.x, p2.x), max(q1.x, q2.x))
		min_y := max(min(p1.y, p2.y), min(q1.y, q2.y))
		max_y := min(max(p1.y, p2.y), max(q1.y, q2.y))
		if positive_x < min_x * positive_denominator || positive_x > max_x * positive_denominator ||
			positive_y < min_y * positive_denominator || positive_y > max_y * positive_denominator { return 0 }
		return write_point(mut output, output_capacity, f64(positive_x) / f64(positive_denominator),
			f64(positive_y) / f64(positive_denominator))
	}
	return write_point(mut output, output_capacity, f64(numerator_x) / f64(denominator),
		f64(numerator_y) / f64(denominator))
}
