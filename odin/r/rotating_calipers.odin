package rotating_calipers

import "core:c"
import "core:math"

MAX_POINTS :: 1024
MAX_COORDINATE :: i64(1_000_000_000)
INVALID_RESULT :: f64 = -1.0e300

Point :: struct { x, y: i64 }

before :: proc(a, b: ^Point) -> bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}
cross :: proc(origin, a, b: ^Point) -> i64 {
	return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
}
distance_squared :: proc(a, b: ^Point) -> i64 {
	dx, dy := a.x - b.x, a.y - b.y
	return dx * dx + dy * dy
}
sort_points :: proc(points, scratch: [^]Point, begin, end: int) {
	if end - begin < 2 do return
	middle := begin + (end - begin) / 2
	sort_points(points, scratch, begin, middle)
	sort_points(points, scratch, middle, end)
	left, right, out := begin, middle, begin
	for left < middle && right < end {
		if before(&points[right], &points[left]) {
			scratch[out] = points[right]
			right += 1
		} else {
			scratch[out] = points[left]
			left += 1
		}
		out += 1
	}
	for left < middle { scratch[out] = points[left]; left += 1; out += 1 }
	for right < end { scratch[out] = points[right]; right += 1; out += 1 }
	for i := begin; i < end; i += 1 { points[i] = scratch[i] }
}

@(export)
rotating_calipers :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 2 * MAX_POINTS + 1 || length % 2 == 0 do return INVALID_RESULT
	count_value := values[0]
	if count_value < 2 || count_value > MAX_POINTS || length != 1 + 2 * c.size_t(count_value) do return INVALID_RESULT
	count := int(count_value)
	points: [MAX_POINTS]Point
	scratch: [MAX_POINTS]Point
	for i := 0; i < count; i += 1 {
		x, y := values[1 + 2 * i], values[2 + 2 * i]
		if x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE do return INVALID_RESULT
		points[i] = Point{x, y}
	}
	sort_points(&points[0], &scratch[0], 0, count)
	unique_count := 0
	for i := 0; i < count; i += 1 {
		if unique_count == 0 || points[i].x != points[unique_count - 1].x || points[i].y != points[unique_count - 1].y {
			points[unique_count] = points[i]
			unique_count += 1
		}
	}
	if unique_count == 1 do return 0.0
	var lower: [MAX_POINTS]Point
	var upper: [MAX_POINTS]Point
	lower_count := 0
	for i := 0; i < unique_count; i += 1 {
		for lower_count >= 2 && cross(&lower[lower_count - 2], &lower[lower_count - 1], &points[i]) <= 0 { lower_count -= 1 }
		lower[lower_count] = points[i]
		lower_count += 1
	}
	upper_count := 0
	for i := unique_count; i > 0; {
		i -= 1
		for upper_count >= 2 && cross(&upper[upper_count - 2], &upper[upper_count - 1], &points[i]) <= 0 { upper_count -= 1 }
		upper[upper_count] = points[i]
		upper_count += 1
	}
	var hull: [2 * MAX_POINTS]Point
	hull_count := 0
	for i := 0; i + 1 < lower_count; i += 1 { hull[hull_count] = lower[i]; hull_count += 1 }
	for i := 0; i + 1 < upper_count; i += 1 { hull[hull_count] = upper[i]; hull_count += 1 }
	if hull_count == 2 do return math.sqrt(f64(distance_squared(&hull[0], &hull[1])))

	antipodal, advances := 1, 0
	for advances < hull_count && cross(&hull[0], &hull[1], &hull[(antipodal + 1) % hull_count]) > cross(&hull[0], &hull[1], &hull[antipodal]) {
		antipodal = (antipodal + 1) % hull_count
		advances += 1
	}
	maximum_squared: i64 = 0
	for current := 0; current < hull_count; current += 1 {
		next := (current + 1) % hull_count
		advances = 0
		for advances < hull_count && cross(&hull[current], &hull[next], &hull[(antipodal + 1) % hull_count]) > cross(&hull[current], &hull[next], &hull[antipodal]) {
			antipodal = (antipodal + 1) % hull_count
			advances += 1
		}
		after := (antipodal + 1) % hull_count
		candidates := [4]i64{
			distance_squared(&hull[current], &hull[antipodal]),
			distance_squared(&hull[next], &hull[antipodal]),
			distance_squared(&hull[current], &hull[after]),
			distance_squared(&hull[next], &hull[after]),
		}
		for candidate in candidates { if candidate > maximum_squared do maximum_squared = candidate }
	}
	return math.sqrt(f64(maximum_squared))
}
