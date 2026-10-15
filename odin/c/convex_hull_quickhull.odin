package convex_hull_quickhull

import "core:c"

MAX_POINTS :: 1024
Point :: struct { x, y: i64, id: int }

before :: proc(a, b: Point) -> bool {
	if a.x != b.x do return a.x < b.x
	if a.y != b.y do return a.y < b.y
	return a.id < b.id
}
cross :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
sort_points :: proc(points, scratch: [^]Point, begin, end: int) {
	if end - begin < 2 do return
	middle := begin + (end - begin) / 2
	sort_points(points, scratch, begin, middle)
	sort_points(points, scratch, middle, end)
	left, right, out := begin, middle, begin
	for left < middle && right < end {
		if before(points[right], points[left]) { scratch[out] = points[right]; right += 1 }
		else { scratch[out] = points[left]; left += 1 }
		out += 1
	}
	for left < middle { scratch[out] = points[left]; left += 1; out += 1 }
	for right < end { scratch[out] = points[right]; right += 1; out += 1 }
	for index := begin; index < end; index += 1 { points[index] = scratch[index] }
}
quick_hull :: proc(points: [^]Point, count, left, right: int, on_hull: [^]bool) {
	farthest := -1
	greatest_area: i64 = 0
	for index := 0; index < count; index += 1 {
		area := cross(points[left], points[right], points[index])
		if area > greatest_area { greatest_area = area; farthest = index }
	}
	if farthest < 0 do return
	on_hull[farthest] = true
	quick_hull(points, count, left, farthest, on_hull)
	quick_hull(points, count, farthest, right, on_hull)
}
write_index :: proc(output: [^]u8, position, id: int) {
	value := u32(id)
	for byte := 0; byte < 4; byte += 1 { output[4 * position + byte] = u8((value >> u32(8 * byte)) & 255) }
}

@(export)
convex_hull_quickhull :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == nil) do return -1
	input_count := int(length / 2)
	points, scratch: [MAX_POINTS]Point
	for index := 0; index < input_count; index += 1 {
		x, y := values[2 * index], values[2 * index + 1]
		if x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000 do return -1
		points[index] = Point{x = x, y = y, id = index}
	}
	if input_count == 0 do return 0
	sort_points(&points[0], &scratch[0], 0, input_count)
	count := 0
	for index := 0; index < input_count; index += 1 {
		point := points[index]
		if count == 0 || points[count - 1].x != point.x || points[count - 1].y != point.y {
			points[count] = point
			count += 1
		}
	}
	on_hull: [MAX_POINTS]bool
	for index := 0; index < MAX_POINTS; index += 1 { on_hull[index] = false }
	if count == 1 {
		on_hull[0] = true
	} else {
		on_hull[0] = true
		on_hull[count - 1] = true
		quick_hull(&points[0], count, 0, count - 1, &on_hull[0])
		quick_hull(&points[0], count, count - 1, 0, &on_hull[0])
	}
	hull_count := 0
	for index := 0; index < count; index += 1 { if on_hull[index] { hull_count += 1 } }
	if output == nil || output_capacity < c.size_t(4 * hull_count) do return -2
	position := 0
	for index := 0; index < count; index += 1 {
		if !on_hull[index] do continue
		write_index(output, position, points[index].id)
		position += 1
	}
	return i64(hull_count)
}
