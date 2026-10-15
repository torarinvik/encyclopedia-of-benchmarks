module smallest_circle

import math

struct Point {
	x i64
	y i64
}

struct Circle {
	x f64
	y f64
	radius f64
	valid bool
}

fn contains(points []Point, circle Circle) bool {
	radius_squared := circle.radius * circle.radius
	for point in points {
		dx := f64(point.x) - circle.x
		dy := f64(point.y) - circle.y
		if dx * dx + dy * dy > radius_squared + 1.0e-12 { return false }
	}
	return true
}

fn consider(points []Point, candidate Circle, mut best Circle) {
	if contains(points, candidate) && (!best.valid || candidate.radius <= best.radius) {
		best = candidate
	}
}

fn write_circle(mut output &u8, capacity usize, circle Circle) i64 {
	if unsafe { output == nil } || capacity < 24 { return -2 }
	for value_index, value in [circle.x, circle.y, circle.radius] {
		mut bits := math.bits_from_f64(value)
		for byte_index in 0 .. 8 {
			unsafe { output[value_index * 8 + byte_index] = u8(bits & 255) }
			bits >>= 8
		}
	}
	return 1
}

// Enumerate circumcircles and diameter circles in the source algorithm's deterministic order.
@[export: 'smallest_circle']
pub fn smallest_circle(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 24 || length % 2 != 0 { return -1 }
	unsafe {
		count := int(length / 2)
		if count < 1 || count > 12 { return -1 }
		mut points := []Point{len: count}
		for index in 0 .. count {
			x := input[2 * index]
			y := input[2 * index + 1]
			if x < -100 || x > 100 || y < -100 || y > 100 { return -1 }
			points[index] = Point{x, y}
		}
		if count == 1 {
			return write_circle(mut output, output_capacity, Circle{f64(points[0].x), f64(points[0].y), 0.0, true})
		}
		mut best := Circle{}
		for i in 0 .. count {
			for j in i + 1 .. count {
				for k in j + 1 .. count {
					a := points[i]
					b := points[j]
					c := points[k]
					ax, ay, bx, by, cx, cy := f64(a.x), f64(a.y), f64(b.x), f64(b.y), f64(c.x), f64(c.y)
					denominator := 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
					if denominator == 0.0 { continue }
					a_squared, b_squared, c_squared := ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
					center_x := (a_squared * (by - cy) + b_squared * (cy - ay) + c_squared * (ay - by)) / denominator
					center_y := (a_squared * (cx - bx) + b_squared * (ax - cx) + c_squared * (bx - ax)) / denominator
					dx, dy := ax - center_x, ay - center_y
					consider(points, Circle{center_x, center_y, math.sqrt(dx * dx + dy * dy), true}, mut best)
				}
			}
		}
		for i in 0 .. count {
			for j in i + 1 .. count {
				center_x := (f64(points[i].x) + f64(points[j].x)) / 2.0
				center_y := (f64(points[i].y) + f64(points[j].y)) / 2.0
				dx, dy := f64(points[i].x) - center_x, f64(points[i].y) - center_y
				consider(points, Circle{center_x, center_y, math.sqrt(dx * dx + dy * dy), true}, mut best)
			}
		}
		if !best.valid { return -1 }
		return write_circle(mut output, output_capacity, best)
	}
}
