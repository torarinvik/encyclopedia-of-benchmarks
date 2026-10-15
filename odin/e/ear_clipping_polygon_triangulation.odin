package ear_clipping_polygon_triangulation

import "core:c"

MAX_VERTICES :: 64
Point :: struct { x, y: i64 }

orient :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
on_segment :: proc(a, b, p: Point) -> bool {
	return orient(a, b, p) == 0 && p.x >= min(a.x, b.x) && p.x <= max(a.x, b.x) &&
		p.y >= min(a.y, b.y) && p.y <= max(a.y, b.y)
}
segments_intersect :: proc(a, b, c, d: Point) -> bool {
	ab_c := orient(a, b, c)
	ab_d := orient(a, b, d)
	cd_a := orient(c, d, a)
	cd_b := orient(c, d, b)
	if ab_c == 0 && on_segment(a, b, c) do return true
	if ab_d == 0 && on_segment(a, b, d) do return true
	if cd_a == 0 && on_segment(c, d, a) do return true
	if cd_b == 0 && on_segment(c, d, b) do return true
	return (ab_c < 0) != (ab_d < 0) && (cd_a < 0) != (cd_b < 0)
}
in_or_on_triangle :: proc(a, b, c, p: Point, winding: i64) -> bool {
	return orient(a, b, p) * winding >= 0 && orient(b, c, p) * winding >= 0 &&
		orient(c, a, p) * winding >= 0
}
write_index :: proc(output: [^]u8, position, slot, index: int) {
	value := u32(index)
	for byte := 0; byte < 4; byte += 1 {
		output[position * 12 + slot * 4 + byte] = u8((value >> u32(8 * byte)) & 255)
	}
}
write_triangle :: proc(output: [^]u8, position, a, b, c: int) {
	write_index(output, position, 0, a)
	write_index(output, position, 1, b)
	write_index(output, position, 2, c)
}

@(export)
ear_clipping_polygon_triangulation :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 6 || length > 2 * MAX_VERTICES || length % 2 != 0 || values == nil do return -1
	n := int(length / 2)
	points: [MAX_VERTICES]Point
	for i := 0; i < n; i += 1 {
		x, y := values[2 * i], values[2 * i + 1]
		if x < -10000 || x > 10000 || y < -10000 || y > 10000 do return -1
		points[i] = Point{x = x, y = y}
		for prior := 0; prior < i; prior += 1 {
			if points[prior].x == x && points[prior].y == y do return -1
		}
	}
	twice_area: i64 = 0
	for i := 0; i < n; i += 1 {
		next := (i + 1) % n
		after := (i + 2) % n
		if orient(points[i], points[next], points[after]) == 0 do return -1
		twice_area += points[i].x * points[next].y - points[i].y * points[next].x
	}
	if twice_area == 0 do return -1
	for i := 0; i < n; i += 1 {
		i_next := (i + 1) % n
		for j := i + 1; j < n; j += 1 {
			j_next := (j + 1) % n
			if i_next == j || j_next == i do continue
			if segments_intersect(points[i], points[i_next], points[j], points[j_next]) do return -1
		}
	}
	required := 12 * (n - 2)
	if output == nil || output_capacity < c.size_t(required) do return -2
	winding := i64(1)
	if twice_area < 0 do winding = -1
	live: [MAX_VERTICES]bool
	for i := 0; i < n; i += 1 { live[i] = true }
	remaining, emitted := n, 0
	for remaining > 3 {
		found := false
		for current := 0; current < n; current += 1 {
			if !live[current] do continue
			previous := (current + n - 1) % n
			for !live[previous] { previous = (previous + n - 1) % n }
			next := (current + 1) % n
			for !live[next] { next = (next + 1) % n }
			if orient(points[previous], points[current], points[next]) * winding <= 0 do continue
			blocked := false
			for candidate := 0; candidate < n; candidate += 1 {
				if live[candidate] && candidate != previous && candidate != current && candidate != next &&
					in_or_on_triangle(points[previous], points[current], points[next], points[candidate], winding) {
					blocked = true
					break
				}
			}
			if blocked do continue
			write_triangle(output, emitted, previous, current, next)
			emitted += 1
			live[current] = false
			remaining -= 1
			found = true
			break
		}
		if !found do return -1
	}
	final_ids: [3]int
	final_count := 0
	for i := 0; i < n; i += 1 {
		if live[i] { final_ids[final_count] = i; final_count += 1 }
	}
	if final_count != 3 do return -1
	write_triangle(output, emitted, final_ids[0], final_ids[1], final_ids[2])
	return i64(n - 2)
}
