package smallest_circle

import "core:c"
import "core:math"

Point :: struct { x, y: i64 }
Circle :: struct { x, y, radius: f64, valid: bool }

contains :: proc(points: [12]Point, count: int, circle: Circle) -> bool {
	radius_squared := circle.radius * circle.radius
	for index := 0; index < count; index += 1 {
		dx := f64(points[index].x) - circle.x
		dy := f64(points[index].y) - circle.y
		if dx*dx + dy*dy > radius_squared + 1.0e-12 do return false
	}
	return true
}

consider :: proc(points: [12]Point, count: int, candidate: Circle, best: Circle) -> Circle {
	if contains(points, count, candidate) && (!best.valid || candidate.radius <= best.radius) do return candidate
	return best
}

write_circle :: proc(output: [^]u8, capacity: c.size_t, circle: Circle) -> i64 {
	if output == nil || capacity < 24 do return -2
	values := [3]f64{circle.x, circle.y, circle.radius}
	for value_index := 0; value_index < 3; value_index += 1 {
		bits := transmute(u64)values[value_index]
		for byte_index := 0; byte_index < 8; byte_index += 1 {
			output[value_index*8+byte_index] = u8((bits >> u64(byte_index*8)) & 255)
		}
	}
	return 1
}

@(export)
smallest_circle :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 24 || length % 2 != 0 do return -1
	count := int(length / 2)
	if count < 1 || count > 12 do return -1
	points: [12]Point
	for index := 0; index < count; index += 1 {
		x, y := input[2*index], input[2*index+1]
		if x < -100 || x > 100 || y < -100 || y > 100 do return -1
		points[index] = Point{x, y}
	}
	if count == 1 do return write_circle(output, output_capacity,
		Circle{f64(points[0].x), f64(points[0].y), 0, true})

	best := Circle{}
	for i := 0; i < count; i += 1 {
		for j := i+1; j < count; j += 1 {
			for k := j+1; k < count; k += 1 {
				a, b, d := points[i], points[j], points[k]
				ax, ay, bx, by, dx, dy := f64(a.x), f64(a.y), f64(b.x), f64(b.y), f64(d.x), f64(d.y)
				denominator := 2.0 * (ax*(by-dy) + bx*(dy-ay) + dx*(ay-by))
				if denominator == 0 do continue
				a2, b2, d2 := ax*ax+ay*ay, bx*bx+by*by, dx*dx+dy*dy
				center_x := (a2*(by-dy) + b2*(dy-ay) + d2*(ay-by)) / denominator
				center_y := (a2*(dx-bx) + b2*(ax-dx) + d2*(bx-ax)) / denominator
				vx, vy := ax-center_x, ay-center_y
				candidate := Circle{center_x, center_y, math.sqrt(vx*vx + vy*vy), true}
				best = consider(points, count, candidate, best)
			}
		}
	}
	for i := 0; i < count; i += 1 {
		for j := i+1; j < count; j += 1 {
			center_x := (f64(points[i].x) + f64(points[j].x)) / 2.0
			center_y := (f64(points[i].y) + f64(points[j].y)) / 2.0
			vx, vy := f64(points[i].x)-center_x, f64(points[i].y)-center_y
			candidate := Circle{center_x, center_y, math.sqrt(vx*vx + vy*vy), true}
			best = consider(points, count, candidate, best)
		}
	}
	if !best.valid do return -1
	return write_circle(output, output_capacity, best)
}
