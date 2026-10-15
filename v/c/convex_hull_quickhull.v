module convex_hull_quickhull

const max_points = 1024

struct Point {
	x i64
	y i64
	id int
}

fn before(a Point, b Point) bool {
	if a.x != b.x { return a.x < b.x }
	if a.y != b.y { return a.y < b.y }
	return a.id < b.id
}

fn cross(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
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

fn quick_hull(points []Point, count int, left int, right int, mut on_hull []bool) {
	mut farthest := -1
	mut greatest_area := i64(0)
	for index in 0 .. count {
		area := cross(points[left], points[right], points[index])
		if area > greatest_area { greatest_area = area; farthest = index }
	}
	if farthest < 0 { return }
	on_hull[farthest] = true
	quick_hull(points, count, left, farthest, mut on_hull)
	quick_hull(points, count, farthest, right, mut on_hull)
}

fn write_index(output &u8, position int, id int) {
	value := u32(id)
	unsafe {
		for byte in 0 .. 4 { output[4 * position + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

@[export: 'convex_hull_quickhull']
pub fn convex_hull_quickhull(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length > 2 * max_points || length % 2 != 0 || (length != 0 && values == nil) { return -1 }
	input_count := int(length / 2)
	mut points := []Point{len: input_count}
	mut scratch := []Point{len: input_count}
	unsafe {
		for index in 0 .. input_count {
			x := values[2 * index]
			y := values[2 * index + 1]
			if x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000 { return -1 }
			points[index] = Point{x: x, y: y, id: index}
		}
	}
	if input_count == 0 { return 0 }
	sort_points(mut points, mut scratch, 0, input_count)
	mut count := 0
	for index in 0 .. input_count {
		point := points[index]
		if count == 0 || points[count - 1].x != point.x || points[count - 1].y != point.y {
			points[count] = point
			count++
		}
	}
	mut on_hull := []bool{len: count}
	if count == 1 { on_hull[0] = true }
	else {
		on_hull[0] = true
		on_hull[count - 1] = true
		quick_hull(points, count, 0, count - 1, mut on_hull)
		quick_hull(points, count, count - 1, 0, mut on_hull)
	}
	mut hull_count := 0
	for index in 0 .. count { if on_hull[index] { hull_count++ } }
	if output == nil || output_capacity < usize(4 * hull_count) { return -2 }
	mut position := 0
	for index in 0 .. count {
		if !on_hull[index] { continue }
		write_index(output, position, points[index].id)
		position++
	}
	return i64(hull_count)
}
