package convex_hull_graham_scan

import "core:c"

MAX_POINTS :: 1024
Point :: struct { x, y: i64, id: int }

cross :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
radius_squared :: proc(pivot, point: Point) -> i64 {
	dx := point.x - pivot.x
	dy := point.y - pivot.y
	return dx * dx + dy * dy
}
before_x :: proc(left, right: int, points: [^]Point) -> bool {
	if points[left].x != points[right].x do return points[left].x < points[right].x
	if points[left].y != points[right].y do return points[left].y < points[right].y
	return points[left].id < points[right].id
}
before_angle :: proc(left, right: int, points: [^]Point, pivot_index: int) -> bool {
	pivot := points[pivot_index]
	turn := cross(pivot, points[left], points[right])
	if turn != 0 do return turn > 0
	left_radius := radius_squared(pivot, points[left])
	right_radius := radius_squared(pivot, points[right])
	if left_radius != right_radius do return left_radius < right_radius
	return points[left].id < points[right].id
}
sort_indices :: proc(items, scratch: [^]int, begin, end: int, points: [^]Point,
		pivot_index: int, by_angle: bool) {
	if end - begin < 2 do return
	middle := begin + (end - begin) / 2
	sort_indices(items, scratch, begin, middle, points, pivot_index, by_angle)
	sort_indices(items, scratch, middle, end, points, pivot_index, by_angle)
	left, right, out := begin, middle, begin
	for left < middle && right < end {
		right_first := if by_angle { before_angle(items[right], items[left], points, pivot_index) } else { before_x(items[right], items[left], points) }
		if right_first { scratch[out] = items[right]; right += 1 } else { scratch[out] = items[left]; left += 1 }
		out += 1
	}
	for left < middle { scratch[out] = items[left]; left += 1; out += 1 }
	for right < end { scratch[out] = items[right]; right += 1; out += 1 }
	for index := begin; index < end; index += 1 { items[index] = scratch[index] }
}
write_index :: proc(output: [^]u8, position, id: int) {
	value := u32(id)
	for byte := 0; byte < 4; byte += 1 { output[4 * position + byte] = u8((value >> u32(8 * byte)) & 255) }
}

@(export)
convex_hull_graham_scan :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == nil) do return -1
	point_count := int(length / 2)
	input_points: [MAX_POINTS]Point
	points: [MAX_POINTS]Point
	order, scratch, hull: [MAX_POINTS]int
	for index := 0; index < point_count; index += 1 {
		x, y := values[2 * index], values[2 * index + 1]
		if x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000 do return -1
		input_points[index] = Point{x = x, y = y, id = index}
		order[index] = index
	}
	if point_count == 0 do return 0
	sort_indices(&order[0], &scratch[0], 0, point_count, &input_points[0], 0, false)
	unique_count := 0
	for index := 0; index < point_count; index += 1 {
		point := input_points[order[index]]
		if unique_count == 0 || points[unique_count - 1].x != point.x || points[unique_count - 1].y != point.y {
			points[unique_count] = point
			unique_count += 1
		}
	}
	if unique_count == 1 {
		if output == nil || output_capacity < 4 do return -2
		write_index(output, 0, points[0].id)
		return 1
	}
	pivot := 0
	for index := 1; index < unique_count; index += 1 {
		if points[index].y < points[pivot].y || (points[index].y == points[pivot].y && points[index].x < points[pivot].x) { pivot = index }
		order[index] = index
	}
	order[0] = 0
	sort_indices(&order[0], &scratch[0], 0, unique_count, &points[0], pivot, true)
	all_collinear := true
	for index := 2; index < unique_count; index += 1 {
		if cross(points[pivot], points[order[1]], points[order[index]]) != 0 { all_collinear = false }
	}
	if !all_collinear {
		ray_begin := unique_count - 1
		for ray_begin > 1 && cross(points[pivot], points[order[ray_begin - 1]], points[order[unique_count - 1]]) == 0 { ray_begin -= 1 }
		left, right := ray_begin, unique_count - 1
		for left < right { temporary := order[left]; order[left] = order[right]; order[right] = temporary; left += 1; right -= 1 }
	}
	hull_count := 0
	for index := 0; index < unique_count; index += 1 {
		point := order[index]
		for hull_count >= 2 && cross(points[hull[hull_count - 2]], points[hull[hull_count - 1]], points[point]) < 0 { hull_count -= 1 }
		hull[hull_count] = point
		hull_count += 1
	}
	if output == nil || output_capacity < c.size_t(4 * hull_count) do return -2
	for index := 0; index < hull_count; index += 1 { write_index(output, index, points[hull[index]].id) }
	return i64(hull_count)
}
