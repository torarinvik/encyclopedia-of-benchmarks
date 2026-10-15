package line_segment_intersection

Point :: struct { x, y: i64 }

orient :: proc(a, b, c: Point) -> i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

on_segment :: proc(a, b, p: Point) -> bool {
	return min(a.x, b.x) <= p.x && p.x <= max(a.x, b.x) &&
		min(a.y, b.y) <= p.y && p.y <= max(a.y, b.y)
}

@(export)
line_segment_intersection :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	_ = output
	_ = output_capacity
	if length != 8 || values == nil do return -1
	for index := 0; index < 8; index += 1 {
		if values[index] < -10000 || values[index] > 10000 do return -1
	}
	a := Point{x = values[0], y = values[1]}
	b := Point{x = values[2], y = values[3]}
	c := Point{x = values[4], y = values[5]}
	d := Point{x = values[6], y = values[7]}
	ab_c, ab_d := orient(a, b, c), orient(a, b, d)
	cd_a, cd_b := orient(c, d, a), orient(c, d, b)
	if ab_c == 0 && on_segment(a, b, c) do return 1
	if ab_d == 0 && on_segment(a, b, d) do return 1
	if cd_a == 0 && on_segment(c, d, a) do return 1
	if cd_b == 0 && on_segment(c, d, b) do return 1
	if ((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
		((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0)) do return 1
	return 0
}
