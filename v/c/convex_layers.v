module convex_layers

const max_points = 64
const coord_limit = i64(1_000_000)

struct Point {
	x i64
	y i64
}

fn cross(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn before(a Point, b Point) bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}

fn on_segment(point Point, a Point, b Point) bool {
	return cross(a, b, point) == 0 && min(a.x, b.x) <= point.x && point.x <= max(a.x, b.x) &&
		min(a.y, b.y) <= point.y && point.y <= max(a.y, b.y)
}

@[export: 'convex_layers']
pub fn convex_layers(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 1 + 2 * max_points { return -1 }
	raw_count := unsafe { input[0] }
	if raw_count < 0 || raw_count > max_points { return -1 }
	input_count := int(raw_count)
	if length != usize(1 + 2 * input_count) { return -1 }

	mut points := []Point{}
	for index in 0 .. input_count {
		x := unsafe { input[1 + 2 * index] }
		y := unsafe { input[2 + 2 * index] }
		if x < -coord_limit || x > coord_limit || y < -coord_limit || y > coord_limit { return -1 }
		mut duplicate := false
		for old in points {
			if old.x == x && old.y == y { duplicate = true }
		}
		if !duplicate { points << Point{x: x, y: y} }
	}

	mut layers := i64(0)
	for points.len > 0 {
		for index in 1 .. points.len {
			key := points[index]
			mut position := index
			for position > 0 && before(key, points[position - 1]) {
				points[position] = points[position - 1]
				position--
			}
			points[position] = key
		}

		mut hull := []Point{cap: 2 * points.len}
		for point in points {
			for hull.len >= 2 && cross(hull[hull.len - 2], hull[hull.len - 1], point) <= 0 {
				hull.delete(hull.len - 1)
			}
			hull << point
		}
		lower := hull.len
		mut cursor := points.len - 1
		for cursor > 0 {
			point := points[cursor - 1]
			for hull.len > lower && cross(hull[hull.len - 2], hull[hull.len - 1], point) <= 0 {
				hull.delete(hull.len - 1)
			}
			hull << point
			cursor--
		}
		if hull.len > 1 { hull.delete(hull.len - 1) }

		mut boundary := []bool{len: points.len, init: false}
		if hull.len <= 2 {
			for index in 0 .. points.len { boundary[index] = true }
		} else {
			for index, point in points {
				for edge in 0 .. hull.len {
					if on_segment(point, hull[edge], hull[(edge + 1) % hull.len]) {
						boundary[index] = true
						break
					}
				}
			}
		}
		mut remaining := []Point{}
		for index, point in points {
			if !boundary[index] { remaining << point }
		}
		if remaining.len == points.len { return -1 }
		points = remaining
		layers++
	}
	return layers
}
