module convex_hull_graham_scan

const max_points = 1024

struct Point {
	x i64
	y i64
	id int
}

fn cross(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn radius_squared(pivot Point, point Point) i64 {
	dx := point.x - pivot.x
	dy := point.y - pivot.y
	return dx * dx + dy * dy
}

fn before_x(left int, right int, points []Point) bool {
	if points[left].x != points[right].x { return points[left].x < points[right].x }
	if points[left].y != points[right].y { return points[left].y < points[right].y }
	return points[left].id < points[right].id
}

fn before_angle(left int, right int, points []Point, pivot_index int) bool {
	pivot := points[pivot_index]
	turn := cross(pivot, points[left], points[right])
	if turn != 0 { return turn > 0 }
	left_radius := radius_squared(pivot, points[left])
	right_radius := radius_squared(pivot, points[right])
	if left_radius != right_radius { return left_radius < right_radius }
	return points[left].id < points[right].id
}

fn sort_indices(mut items []int, mut scratch []int, begin int, end int,
		points []Point, pivot_index int, by_angle bool) {
	if end - begin < 2 { return }
	middle := begin + (end - begin) / 2
	sort_indices(mut items, mut scratch, begin, middle, points, pivot_index, by_angle)
	sort_indices(mut items, mut scratch, middle, end, points, pivot_index, by_angle)
	mut left := begin
	mut right := middle
	mut out := begin
	for left < middle && right < end {
		right_first := if by_angle { before_angle(items[right], items[left], points, pivot_index) } else { before_x(items[right], items[left], points) }
		if right_first { scratch[out] = items[right]; right++ } else { scratch[out] = items[left]; left++ }
		out++
	}
	for left < middle { scratch[out] = items[left]; left++; out++ }
	for right < end { scratch[out] = items[right]; right++; out++ }
	for index in begin .. end { items[index] = scratch[index] }
}

fn write_index(output &u8, position int, id int) {
	value := u32(id)
	unsafe {
		for byte in 0 .. 4 { output[4 * position + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

@[export: 'convex_hull_graham_scan']
pub fn convex_hull_graham_scan(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length > 2 * max_points || length % 2 != 0 || (length != 0 && values == nil) { return -1 }
	point_count := int(length / 2)
	mut input_points := []Point{cap: point_count}
	for index in 0 .. point_count {
		x := unsafe { values[2 * index] }
		y := unsafe { values[2 * index + 1] }
		if x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000 { return -1 }
		input_points << Point{x: x, y: y, id: index}
	}
	if point_count == 0 { return 0 }
	mut input_order := []int{len: point_count}
	mut scratch := []int{len: point_count}
	for index in 0 .. point_count { input_order[index] = index }
	sort_indices(mut input_order, mut scratch, 0, point_count, input_points, 0, false)
	mut points := []Point{cap: point_count}
	for index in 0 .. point_count {
		point := input_points[input_order[index]]
		if points.len == 0 || points[points.len - 1].x != point.x || points[points.len - 1].y != point.y { points << point }
	}
	if points.len == 1 {
		if output == nil || output_capacity < 4 { return -2 }
		write_index(output, 0, points[0].id)
		return 1
	}
	mut pivot := 0
	for index in 1 .. points.len {
		if points[index].y < points[pivot].y || (points[index].y == points[pivot].y && points[index].x < points[pivot].x) { pivot = index }
	}
	mut order := []int{len: points.len}
	mut hull := []int{cap: points.len}
	for index in 0 .. points.len { order[index] = index }
	sort_indices(mut order, mut scratch, 0, points.len, points, pivot, true)
	mut all_collinear := true
	for index in 2 .. points.len {
		if cross(points[pivot], points[order[1]], points[order[index]]) != 0 { all_collinear = false }
	}
	if !all_collinear {
		mut ray_begin := points.len - 1
		for ray_begin > 1 && cross(points[pivot], points[order[ray_begin - 1]], points[order[points.len - 1]]) == 0 { ray_begin-- }
		mut left := ray_begin
		mut right := points.len - 1
		for left < right { temporary := order[left]; order[left] = order[right]; order[right] = temporary; left++; right-- }
	}
	for point in order {
		for hull.len >= 2 && cross(points[hull[hull.len - 2]], points[hull[hull.len - 1]], points[point]) < 0 { hull.delete_last() }
		hull << point
	}
	if output == nil || output_capacity < usize(4 * hull.len) { return -2 }
	for index, point in hull { write_index(output, index, points[point].id) }
	return i64(hull.len)
}
