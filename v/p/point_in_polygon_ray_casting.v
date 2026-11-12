module point_in_polygon_ray_casting

@[export: 'point_in_polygon_ray_casting']
pub fn point_in_polygon_ray_casting(values &i64, length usize) i64 {
	unsafe {
		if isnil(values) || length < 9 || length > 131 { return -1 }
		n := values[0]
		if n < 3 || n > 64 || length != usize(3 + 2 * n) { return -1 }
		qx, qy := values[1], values[2]
		if qx < -1_000_000 || qx > 1_000_000 || qy < -1_000_000 || qy > 1_000_000 { return -1 }
		for index in 3 .. length {
			if values[index] < -1_000_000 || values[index] > 1_000_000 { return -1 }
		}

		mut inside := false
		for i in 0 .. usize(n) {
			j := (i + 1) % usize(n)
			ax, ay := values[3 + 2 * i], values[4 + 2 * i]
			bx, by := values[3 + 2 * j], values[4 + 2 * j]
			turn := (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
			if turn == 0 && qx >= min(ax, bx) && qx <= max(ax, bx) && qy >= min(ay, by) && qy <= max(ay, by) { return 1 }
			if (ay > qy) != (by > qy) && ((by > ay && turn > 0) || (by < ay && turn < 0)) { inside = !inside }
		}
		return if inside { 1 } else { 0 }
	}
}
