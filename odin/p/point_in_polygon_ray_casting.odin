package point_in_polygon_ray_casting

import "core:c"

@(export)
point_in_polygon_ray_casting :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < c.size_t(9) || length > c.size_t(131) do return -1
	n := values[0]
	if n < 3 || n > 64 || length != c.size_t(3 + 2*n) do return -1
	qx, qy := values[1], values[2]
	if qx < -1_000_000 || qx > 1_000_000 || qy < -1_000_000 || qy > 1_000_000 do return -1
	for i: c.size_t = 3; i < length; i += 1 {
		if values[i] < -1_000_000 || values[i] > 1_000_000 do return -1
	}

	inside := false
	vertex_count := c.size_t(n)
	for i: c.size_t = 0; i < vertex_count; i += 1 {
		j := (i + 1) % vertex_count
		ax, ay := values[3+2*i], values[4+2*i]
		bx, by := values[3+2*j], values[4+2*j]
		turn := (bx-ax)*(qy-ay) - (by-ay)*(qx-ax)
		if turn == 0 && qx >= min(ax,bx) && qx <= max(ax,bx) && qy >= min(ay,by) && qy <= max(ay,by) do return 1
		if (ay > qy) != (by > qy) && ((by > ay && turn > 0) || (by < ay && turn < 0)) { inside = !inside }
	}
	return i64(inside)
}
