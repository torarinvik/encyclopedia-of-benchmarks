module line_segment_intersection

struct Point {
	x i64
	y i64
}

fn cross(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(a Point, b Point, p Point) bool {
	return cross(a, b, p) == 0 &&
		p.x >= min(a.x, b.x) && p.x <= max(a.x, b.x) &&
		p.y >= min(a.y, b.y) && p.y <= max(a.y, b.y)
}

fn sign(value i64) int {
	if value < 0 { return -1 }
	if value > 0 { return 1 }
	return 0
}

// Return one when the two finite closed segments intersect, otherwise zero.
@[export: 'line_segment_intersection']
pub fn line_segment_intersection(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	_ = output
	_ = output_capacity
	if length != 8 || unsafe { values == nil } { return -1 }
	for index in 0 .. 8 {
		if values[index] < -10000 || values[index] > 10000 { return -1 }
	}

	a := Point{values[0], values[1]}
	b := Point{values[2], values[3]}
	c := Point{values[4], values[5]}
	d := Point{values[6], values[7]}

	o1 := cross(a, b, c)
	o2 := cross(a, b, d)
	o3 := cross(c, d, a)
	o4 := cross(c, d, b)
	if o1 == 0 && on_segment(a, b, c) { return 1 }
	if o2 == 0 && on_segment(a, b, d) { return 1 }
	if o3 == 0 && on_segment(c, d, a) { return 1 }
	if o4 == 0 && on_segment(c, d, b) { return 1 }
	return if sign(o1) * sign(o2) < 0 && sign(o3) * sign(o4) < 0 { i64(1) } else { i64(0) }
}
