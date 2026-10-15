module rotating_calipers

import math

const max_points = 1024
const max_coordinate = i64(1000000000)
const invalid_result = -1.0e300

struct Point {
	x i64
	y i64
}

fn before(a Point, b Point) bool {
	return a.x < b.x || (a.x == b.x && a.y < b.y)
}

fn cross(origin Point, a Point, b Point) i64 {
	return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
}

fn distance_squared(a Point, b Point) i64 {
	dx, dy := a.x - b.x, a.y - b.y
	return dx * dx + dy * dy
}

fn sort_points(mut points []Point, mut scratch []Point, begin int, end int) {
	if end - begin < 2 { return }
	middle := begin + (end - begin) / 2
	sort_points(mut points, mut scratch, begin, middle)
	sort_points(mut points, mut scratch, middle, end)
	mut left := begin
	mut right := middle
	mut out := begin
	for left < middle && right < end {
		if before(points[right], points[left]) { scratch[out] = points[right]; right++ }
		else { scratch[out] = points[left]; left++ }
		out++
	}
	for left < middle { scratch[out] = points[left]; left++; out++ }
	for right < end { scratch[out] = points[right]; right++; out++ }
	for index in begin .. end { points[index] = scratch[index] }
}

@[export: 'rotating_calipers']
pub fn rotating_calipers(values &i64, length usize) f64 {
	if length < 5 || length > 2 * max_points + 1 || length % 2 == 0 { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 2 || count_value > max_points || length != usize(1 + 2 * count_value) {
			return invalid_result
		}
		count := int(count_value)
		mut points := []Point{len: count}
		mut scratch := []Point{len: count}
		for index in 0 .. count {
			x, y := values[1 + 2 * index], values[2 + 2 * index]
			if x < -max_coordinate || x > max_coordinate || y < -max_coordinate || y > max_coordinate {
				return invalid_result
			}
			points[index] = Point{x: x, y: y}
		}
		sort_points(mut points, mut scratch, 0, count)
		mut unique_count := 0
		for index in 0 .. count {
			point := points[index]
			if unique_count == 0 || points[unique_count - 1].x != point.x || points[unique_count - 1].y != point.y {
				points[unique_count] = point
				unique_count++
			}
		}
		points = points[..unique_count]
		if unique_count == 1 { return 0.0 }

		mut lower := []Point{cap: unique_count}
		for point in points {
			for lower.len >= 2 && cross(lower[lower.len - 2], lower[lower.len - 1], point) <= 0 {
				lower = lower[..lower.len - 1]
			}
			lower << point
		}
		mut upper := []Point{cap: unique_count}
		for index := unique_count - 1; index >= 0; index-- {
			point := points[index]
			for upper.len >= 2 && cross(upper[upper.len - 2], upper[upper.len - 1], point) <= 0 {
				upper = upper[..upper.len - 1]
			}
			upper << point
		}
		mut hull := []Point{cap: lower.len + upper.len - 2}
		hull << lower[..lower.len - 1]
		hull << upper[..upper.len - 1]
		if hull.len == 2 { return math.sqrt(f64(distance_squared(hull[0], hull[1]))) }

		mut antipodal := 1
		mut advances := 0
		for advances < hull.len && cross(hull[0], hull[1], hull[(antipodal + 1) % hull.len]) >
			cross(hull[0], hull[1], hull[antipodal]) {
			antipodal = (antipodal + 1) % hull.len
			advances++
		}
		mut maximum_squared := i64(0)
		for current in 0 .. hull.len {
			next := (current + 1) % hull.len
			advances = 0
			for advances < hull.len && cross(hull[current], hull[next], hull[(antipodal + 1) % hull.len]) >
				cross(hull[current], hull[next], hull[antipodal]) {
				antipodal = (antipodal + 1) % hull.len
				advances++
			}
			after := (antipodal + 1) % hull.len
			candidates := [4]i64{
				distance_squared(hull[current], hull[antipodal]),
				distance_squared(hull[next], hull[antipodal]),
				distance_squared(hull[current], hull[after]),
				distance_squared(hull[next], hull[after]),
			}
			for candidate in candidates { if candidate > maximum_squared { maximum_squared = candidate } }
		}
		return math.sqrt(f64(maximum_squared))
	}
}
