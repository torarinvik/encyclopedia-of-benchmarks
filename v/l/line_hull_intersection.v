module line_hull_intersection

const max_vertices = 16
const max_parseable_length = 38

struct Point {
mut:
	x i64
	y i64
}

struct Vector {
	x i64
	y i64
}

struct Hit {
	edge i64
	numerator i64
	denominator i64
}

fn polar_half(v Vector) int {
	if v.y > 0 || (v.y == 0 && v.x >= 0) { return 0 }
	return 1
}

fn angle_before(a Vector, b Vector) bool {
	ah, bh := polar_half(a), polar_half(b)
	if ah != bh { return ah < bh }
	return a.x * b.y - a.y * b.x > 0
}

fn rotation_minimum(edges []Vector) int {
	mut low, mut high := 0, edges.len - 1
	for low < high {
		middle := (low + high) / 2
		if angle_before(edges[middle], edges[high]) { high = middle }
		else { low = middle + 1 }
	}
	return low
}

fn support_edge(edges []Vector, target Vector) int {
	count := edges.len
	pivot := rotation_minimum(edges)
	mut low, mut high := 0, count
	for low < high {
		middle := (low + high) / 2
		if angle_before(edges[(pivot + middle) % count], target) { low = middle + 1 }
		else { high = middle }
	}
	return (pivot + low) % count
}

fn line_value(points []Point, index int, origin Point, direction Vector) i64 {
	return direction.x * (points[index].y - origin.y) - direction.y * (points[index].x - origin.x)
}

fn line_parameter(point Point, origin Point, direction Vector) i64 {
	return (point.x - origin.x) * direction.x + (point.y - origin.y) * direction.y
}

fn crossing(points []Point, origin Point, direction Vector, start int, finish int, increasing bool) Hit {
	count := points.len
	span := (finish + count - start) % count
	mut low, mut high := 0, span
	for high - low > 1 {
		middle := (low + high) / 2
		value := line_value(points, (start + middle) % count, origin, direction)
		if (increasing && value < 0) || (!increasing && value > 0) { low = middle }
		else { high = middle }
	}
	mut index := (start + low) % count
	if line_value(points, (start + high) % count, origin, direction) == 0 {
		index = (start + high) % count
	}
	value := line_value(points, index, origin, direction)
	if value == 0 {
		return Hit{edge: i64(index), numerator: line_parameter(points[index], origin, direction), denominator: 1}
	}
	next := (index + 1) % count
	next_value := line_value(points, next, origin, direction)
	mut denominator := value - next_value
	edge_dot := (points[next].x - points[index].x) * direction.x + (points[next].y - points[index].y) * direction.y
	mut numerator := line_parameter(points[index], origin, direction) * denominator + value * edge_dot
	if denominator < 0 { numerator = -numerator; denominator = -denominator }
	return Hit{edge: i64(index), numerator: numerator, denominator: denominator}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'line_hull_intersection']
pub fn line_hull_intersection(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 3 || n_value > max_vertices { return -1 }
		n := int(n_value)
		if length != usize(5 + 2 * n) { return -1 }
		origin := Point{x: input[1], y: input[2]}
		line_end := Point{x: input[3], y: input[4]}
		if origin.x < -50 || origin.x > 50 || origin.y < -50 || origin.y > 50 || line_end.x < -50 || line_end.x > 50 || line_end.y < -50 || line_end.y > 50 { return -1 }
		direction := Vector{x: line_end.x - origin.x, y: line_end.y - origin.y}
		if direction.x == 0 && direction.y == 0 { return -1 }
		mut points := []Point{len: n}
		mut edges := []Vector{len: n}
		for i in 0 .. n {
			points[i] = Point{x: input[5 + 2 * i], y: input[6 + 2 * i]}
			if points[i].x < -50 || points[i].x > 50 || points[i].y < -50 || points[i].y > 50 { return -1 }
			for j in 0 .. i { if points[j].x == points[i].x && points[j].y == points[i].y { return -1 } }
		}
		mut area2 := i64(0)
		for i in 0 .. n {
			next := (i + 1) % n
			edges[i] = Vector{x: points[next].x - points[i].x, y: points[next].y - points[i].y}
			area2 += points[i].x * points[next].y - points[next].x * points[i].y
		}
		if area2 <= 0 { return -1 }
		for i in 0 .. n {
			next := (i + 1) % n
			for j in 0 .. n {
				if j == i || j == next { continue }
				side := edges[i].x * (points[j].y - points[i].y) - edges[i].y * (points[j].x - points[i].x)
				if side <= 0 { return -1 }
			}
		}
		maximum := support_edge(edges, Vector{x: -direction.x, y: -direction.y})
		minimum := support_edge(edges, direction)
		max_value := line_value(points, maximum, origin, direction)
		min_value := line_value(points, minimum, origin, direction)
		mut first, mut second := i64(-1), i64(-1)
		if min_value > 0 || max_value < 0 {
			first, second = -1, -1
		} else if min_value == 0 || max_value == 0 {
			touch := if min_value == 0 { minimum } else { maximum }
			next, previous := (touch + 1) % n, (touch + n - 1) % n
			if line_value(points, touch, origin, direction) == 0 && line_value(points, next, origin, direction) == 0 {
				first, second = i64(touch), i64(touch)
			} else if line_value(points, previous, origin, direction) == 0 && line_value(points, touch, origin, direction) == 0 {
				first, second = i64(previous), i64(previous)
			} else { first, second = i64(touch), -1 }
		} else {
			a := crossing(points, origin, direction, maximum, minimum, false)
			b := crossing(points, origin, direction, minimum, maximum, true)
			if a.numerator * b.denominator <= b.numerator * a.denominator { first, second = a.edge, b.edge }
			else { first, second = b.edge, a.edge }
		}
		if unsafe { output == nil } || capacity < 16 { return -2 }
		store_i64_le(mut output, 0, first)
		store_i64_le(mut output, 8, second)
		return 16
	}
}
