module ear_clipping_polygon_triangulation

const max_vertices = 64

struct Point {
	x i64
	y i64
}

fn orient(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(a Point, b Point, p Point) bool {
	return orient(a, b, p) == 0 && p.x >= min(a.x, b.x) && p.x <= max(a.x, b.x) &&
		p.y >= min(a.y, b.y) && p.y <= max(a.y, b.y)
}

fn segments_intersect(a Point, b Point, c Point, d Point) bool {
	ab_c := orient(a, b, c)
	ab_d := orient(a, b, d)
	cd_a := orient(c, d, a)
	cd_b := orient(c, d, b)
	if ab_c == 0 && on_segment(a, b, c) { return true }
	if ab_d == 0 && on_segment(a, b, d) { return true }
	if cd_a == 0 && on_segment(c, d, a) { return true }
	if cd_b == 0 && on_segment(c, d, b) { return true }
	return (ab_c < 0) != (ab_d < 0) && (cd_a < 0) != (cd_b < 0)
}

fn in_or_on_triangle(a Point, b Point, c Point, p Point, winding i64) bool {
	return orient(a, b, p) * winding >= 0 && orient(b, c, p) * winding >= 0 &&
		orient(c, a, p) * winding >= 0
}

fn write_index(mut output &u8, position int, slot int, index int) {
	value := u32(index)
	unsafe {
		for byte in 0 .. 4 { output[position * 12 + slot * 4 + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

fn write_triangle(mut output &u8, position int, a int, b int, c int) {
	write_index(mut output, position, 0, a)
	write_index(mut output, position, 1, b)
	write_index(mut output, position, 2, c)
}

@[export: 'ear_clipping_polygon_triangulation']
pub fn ear_clipping_polygon_triangulation(values &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	if length < 6 || length > 2 * max_vertices || length % 2 != 0 || unsafe { values == nil } { return -1 }
	n := int(length / 2)
	mut points := []Point{len: n}
	for i in 0 .. n {
		x := unsafe { values[2 * i] }
		y := unsafe { values[2 * i + 1] }
		if x < -10000 || x > 10000 || y < -10000 || y > 10000 { return -1 }
		points[i] = Point{x, y}
		for prior in 0 .. i {
			if points[prior].x == x && points[prior].y == y { return -1 }
		}
	}
	mut twice_area := i64(0)
	for i in 0 .. n {
		next := (i + 1) % n
		after := (i + 2) % n
		if orient(points[i], points[next], points[after]) == 0 { return -1 }
		twice_area += points[i].x * points[next].y - points[i].y * points[next].x
	}
	if twice_area == 0 { return -1 }
	for i in 0 .. n {
		i_next := (i + 1) % n
		for j := i + 1; j < n; j++ {
			j_next := (j + 1) % n
			if i_next == j || j_next == i { continue }
			if segments_intersect(points[i], points[i_next], points[j], points[j_next]) { return -1 }
		}
	}
	required := usize(12 * (n - 2))
	if unsafe { output == nil } || output_capacity < required { return -2 }
	winding := i64(1)
	if twice_area < 0 { winding = -1 }
	mut live := [max_vertices]bool{init: false}
	for i in 0 .. n { live[i] = true }
	mut remaining := n
	mut emitted := 0
	for remaining > 3 {
		mut found := false
		for current in 0 .. n {
			if !live[current] { continue }
			mut previous := (current + n - 1) % n
			for !live[previous] { previous = (previous + n - 1) % n }
			mut next := (current + 1) % n
			for !live[next] { next = (next + 1) % n }
			if orient(points[previous], points[current], points[next]) * winding <= 0 { continue }
			mut blocked := false
			for candidate in 0 .. n {
				if live[candidate] && candidate != previous && candidate != current && candidate != next &&
					in_or_on_triangle(points[previous], points[current], points[next], points[candidate], winding) {
					blocked = true
					break
				}
			}
			if blocked { continue }
			write_triangle(mut output, emitted, previous, current, next)
			emitted++
			live[current] = false
			remaining--
			found = true
			break
		}
		if !found { return -1 }
	}
	mut final_ids := [3]int{}
	mut final_count := 0
	for i in 0 .. n {
		if live[i] { final_ids[final_count] = i; final_count++ }
	}
	if final_count != 3 { return -1 }
	write_triangle(mut output, emitted, final_ids[0], final_ids[1], final_ids[2])
	return i64(n - 2)
}
