const max_coordinate = i64(1000)
const max_radius = i64(1000)

fn classify(x1 i64, y1 i64, r1 i64, x2 i64, y2 i64, r2 i64) i64 {
	dx := x2 - x1
	dy := y2 - y1
	if dx == 0 && dy == 0 {
		if r1 == r2 { return 3 }
		return 0
	}
	a := -2 * dx
	b := -2 * dy
	c := dx * dx + dy * dy + r1 * r1 - r2 * r2
	discriminant := r1 * r1 * (a * a + b * b) - c * c
	if discriminant < 0 { return 0 }
	if discriminant == 0 { return 1 }
	return 2
}

@[export: 'circle_circle_intersection_count']
pub fn circle_circle_intersection_count(input &i64, length usize) i64 {
	if length != 6 { return -1 }
	unsafe {
		if input == nil { return -1 }
		x1, y1, r1 := input[0], input[1], input[2]
		x2, y2, r2 := input[3], input[4], input[5]
		if x1 < -max_coordinate || x1 > max_coordinate ||
			y1 < -max_coordinate || y1 > max_coordinate ||
			x2 < -max_coordinate || x2 > max_coordinate ||
			y2 < -max_coordinate || y2 > max_coordinate ||
			r1 < 1 || r1 > max_radius || r2 < 1 || r2 > max_radius { return -1 }
		return classify(x1, y1, r1, x2, y2, r2)
	}
}
