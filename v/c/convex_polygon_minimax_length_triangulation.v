module convex_polygon_minimax_length_triangulation

const min_vertices = 3
const max_vertices = 12
const max_parseable_length = 26
const coord_limit = i64(1000)

struct Point { x i64; y i64 }

fn cross(a Point, b Point, c Point) i64 {
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn squared_length(points [max_vertices]Point, left int, right int) i64 {
	dx := points[left].x - points[right].x
	dy := points[left].y - points[right].y
	return dx * dx + dy * dy
}

@[export: 'convex_polygon_minimax_length_triangulation']
pub fn convex_polygon_minimax_length_triangulation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if input[0] < min_vertices || input[0] > max_vertices { return -1 }
		n := int(input[0])
		if length != usize(1 + 2 * n) { return -1 }
		mut points := [max_vertices]Point{}
		for i in 0 .. n {
			points[i] = Point{ x: input[1 + 2 * i], y: input[2 + 2 * i] }
			if points[i].x < -coord_limit || points[i].x > coord_limit || points[i].y < -coord_limit || points[i].y > coord_limit { return -1 }
		}
		mut area2 := i64(0)
		for i in 0 .. n {
			next := (i + 1) % n
			area2 += points[i].x * points[next].y - points[i].y * points[next].x
		}
		if area2 == 0 { return -1 }
		orientation := if area2 > 0 { i64(1) } else { i64(-1) }
		for edge in 0 .. n {
			next := (edge + 1) % n
			for vertex in 0 .. n {
				if vertex != edge && vertex != next && orientation * cross(points[edge], points[next], points[vertex]) <= 0 { return -1 }
			}
		}

		mut best := [max_vertices * max_vertices]i64{}
		for left in 0 .. n - 1 { best[left * max_vertices + left + 1] = squared_length(points, left, left + 1) }
		for span in 2 .. n {
			for left in 0 .. n - span {
				right := left + span
				boundary := squared_length(points, left, right)
				mut optimum := i64(8_000_001)
				for middle in left + 1 .. right {
					mut candidate := best[left * max_vertices + middle]
					if best[middle * max_vertices + right] > candidate { candidate = best[middle * max_vertices + right] }
					if boundary > candidate { candidate = boundary }
					if candidate < optimum { optimum = candidate }
				}
				best[left * max_vertices + right] = optimum
			}
		}
		return best[n - 1]
	}
}
