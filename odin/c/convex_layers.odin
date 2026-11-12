package convex_layers

import "core:c"

MAX_POINTS :: 64
COORD_LIMIT :: i64(1_000_000)

Point :: struct { x, y: i64 }

cross :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

before :: proc(a, b: Point) -> bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}

on_segment :: proc(point, a, b: Point) -> bool {
	return cross(a, b, point) == 0 && min(a.x, b.x) <= point.x && point.x <= max(a.x, b.x) &&
		min(a.y, b.y) <= point.y && point.y <= max(a.y, b.y)
}

@(export)
convex_layers :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 1 + 2 * MAX_POINTS do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_POINTS do return -1
	count_input := int(raw_count)
	if length != c.size_t(1 + 2 * count_input) do return -1

	points: [MAX_POINTS]Point
	count := 0
	for index := 0; index < count_input; index += 1 {
		x, y := input[1 + 2 * index], input[2 + 2 * index]
		if x < -COORD_LIMIT || x > COORD_LIMIT || y < -COORD_LIMIT || y > COORD_LIMIT do return -1
		duplicate := false
		for old := 0; old < count; old += 1 {
			if points[old].x == x && points[old].y == y do duplicate = true
		}
		if !duplicate {
			points[count] = Point{x, y}
			count += 1
		}
	}

	layers: i64 = 0
	for count > 0 {
		for index := 1; index < count; index += 1 {
			key := points[index]
			position := index
			for position > 0 && before(key, points[position - 1]) {
				points[position] = points[position - 1]
				position -= 1
			}
			points[position] = key
		}

		hull: [2 * MAX_POINTS]Point
		hull_count := 0
		for index := 0; index < count; index += 1 {
			for hull_count >= 2 && cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0 {
				hull_count -= 1
			}
			hull[hull_count] = points[index]
			hull_count += 1
		}
		lower_count := hull_count
		for index := count - 1; index > 0; index -= 1 {
			point := points[index - 1]
			for hull_count > lower_count && cross(hull[hull_count - 2], hull[hull_count - 1], point) <= 0 {
				hull_count -= 1
			}
			hull[hull_count] = point
			hull_count += 1
		}
		if hull_count > 1 do hull_count -= 1
		boundary: [MAX_POINTS]bool
		if hull_count <= 2 {
			for index := 0; index < count; index += 1 do boundary[index] = true
		} else {
			for index := 0; index < count; index += 1 {
				for edge := 0; edge < hull_count; edge += 1 {
					if on_segment(points[index], hull[edge], hull[(edge + 1) % hull_count]) {
						boundary[index] = true
						break
					}
				}
			}
		}
		kept := 0
		for index := 0; index < count; index += 1 {
			if !boundary[index] {
				points[kept] = points[index]
				kept += 1
			}
		}
		if kept == count do return -1
		count = kept
		layers += 1
	}
	return layers
}
