module external_point_tangents_convex_polygon

const max_vertices = 32
const max_queries = 16
const max_input = 99
const max_coordinate = i64(1000)

struct Point { x i64; y i64 }
fn sub(a Point, b Point) Point { return Point{ x: a.x - b.x, y: a.y - b.y } }
fn cross(a Point, b Point) i64 { return a.x * b.y - a.y * b.x }

fn valid_polygon(p &Point, n int) bool {
	unsafe {
		for i in 0 .. n {
			next := (i + 1) % n
			if p[i].x == p[next].x && p[i].y == p[next].y { return false }
			edge := sub(p[next], p[i])
			for j in 0 .. n { if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 { return false } }
		}
	}
	return true
}
fn valid_query(p &Point, n int, q Point) bool {
	mut outside := false
	unsafe {
		for i in 0 .. n {
			side := cross(sub(p[(i + 1) % n], p[i]), sub(q, p[i]))
			if side == 0 { return false }
			if side < 0 { outside = true }
		}
	}
	return outside
}
fn build_chain(mut chain &int, n int, start int, stop int) int {
	mut length := 0
	mut at := start
	for {
		chain[length] = at
		length++
		if at == stop { return length }
		at = (at + 1) % n
		if length > n { return 0 }
	}
}
fn build_layers(p &Point, n int, mut lower &int, mut upper &int) (int, int) {
	mut min_x := 0
	mut max_x := 0
	unsafe {
		for i in 1 .. n {
			if p[i].x < p[min_x].x { min_x = i }
			if p[i].x > p[max_x].x { max_x = i }
		}
		mut left_bottom := min_x
		mut left_top := min_x
		mut right_bottom := max_x
		mut right_top := max_x
		for i in 0 .. n {
			if p[i].x == p[min_x].x {
				if p[i].y < p[left_bottom].y { left_bottom = i }
				if p[i].y > p[left_top].y { left_top = i }
			}
			if p[i].x == p[max_x].x {
				if p[i].y < p[right_bottom].y { right_bottom = i }
				if p[i].y > p[right_top].y { right_top = i }
			}
		}
		lower_len := build_chain(mut lower, n, left_bottom, right_bottom)
		upper_len := build_chain(mut upper, n, right_top, left_top)
		return lower_len, upper_len
	}
}
fn split_ascending(p &Point, chain &int, length int, qx i64) int {
	mut lo := 0
	mut hi := length
	unsafe {
		for lo < hi {
			mid := lo + (hi - lo) / 2
			if p[chain[mid]].x < qx { lo = mid + 1 } else { hi = mid }
		}
	}
	return if lo == 0 { 0 } else { lo - 1 }
}
fn split_descending(p &Point, chain &int, length int, qx i64) int {
	mut lo := 0
	mut hi := length
	unsafe {
		for lo < hi {
			mid := lo + (hi - lo) / 2
			if p[chain[mid]].x > qx { lo = mid + 1 } else { hi = mid }
		}
	}
	return if lo == 0 { 0 } else { lo - 1 }
}
fn tangent_search(p &Point, n int, chain &int, mut lo int, mut hi int, q Point, sign i64) int {
	mut result := lo
	unsafe {
		for lo <= hi {
			mid := lo + (hi - lo) / 2
			index := chain[mid]
			here := sub(p[index], q)
			to_next := sign * cross(here, sub(p[(index + 1) % n], q))
			to_prev := sign * cross(here, sub(p[(index + n - 1) % n], q))
			if to_next >= 0 && to_prev >= 0 { return mid }
			if to_next >= 0 { result = mid; hi = mid - 1 } else { lo = mid + 1 }
		}
	}
	return result
}
fn supports(p &Point, n int, index int, q Point, sign i64) bool {
	unsafe {
		here := sub(p[index], q)
		return sign * cross(here, sub(p[(index + n - 1) % n], q)) > 0 &&
			sign * cross(here, sub(p[(index + 1) % n], q)) > 0
	}
}
fn find_tangents(p &Point, n int, lower &int, lower_len int, upper &int, upper_len int, q Point) (int, int, bool) {
	unsafe {
		lower_split := split_ascending(p, lower, lower_len, q.x)
		upper_split := split_descending(p, upper, upper_len, q.x)
		left_a := lower[tangent_search(p, n, lower, 0, lower_split, q, -1)]
		left_b := upper[tangent_search(p, n, upper, 0, upper_split, q, -1)]
		right_a := lower[tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)]
		right_b := upper[tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)]
		mut left := -1
		mut right := -1
		if supports(p, n, left_a, q, -1) { left = left_a } else if supports(p, n, left_b, q, -1) { left = left_b }
		if supports(p, n, right_a, q, 1) { right = right_a } else if supports(p, n, right_b, q, 1) { right = right_b }
		if left < 0 || right < 0 || left == right { return -1, -1, false }
		if left < right { return left, right, true }
		return right, left, true
	}
}
fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for b in 0 .. 8 { output[offset + b] = u8((bits >> (8 * b)) & 255) }
	}
}

@[export: 'external_point_tangents_convex_polygon']
pub fn external_point_tangents_convex_polygon(values &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || n < 2 || n > max_input || values[0] < 3 || values[0] > max_vertices ||
			values[1] < 0 || values[1] > max_queries { return -1 }
		vertices := int(values[0])
		queries := int(values[1])
		if n != usize(2 + 2 * vertices + 2 * queries) { return -1 }
		mut polygon := [max_vertices]Point{init: Point{}}
		mut query_points := [max_queries]Point{init: Point{}}
		mut answers := [2 * max_queries]i64{}
		mut at := 2
		for i in 0 .. vertices {
			polygon[i] = Point{ x: values[at], y: values[at + 1] }; at += 2
			if polygon[i].x < -max_coordinate || polygon[i].x > max_coordinate ||
				polygon[i].y < -max_coordinate || polygon[i].y > max_coordinate { return -1 }
		}
		if !valid_polygon(&polygon[0], vertices) { return -1 }
		mut lower := [max_vertices]int{}
		mut upper := [max_vertices]int{}
		lower_len, upper_len := build_layers(&polygon[0], vertices, mut lower[0], mut upper[0])
		if lower_len == 0 || upper_len == 0 { return -1 }
		for i in 0 .. queries {
			query_points[i] = Point{ x: values[at], y: values[at + 1] }; at += 2
			if query_points[i].x < -max_coordinate || query_points[i].x > max_coordinate ||
				query_points[i].y < -max_coordinate || query_points[i].y > max_coordinate ||
				!valid_query(&polygon[0], vertices, query_points[i]) { return -1 }
			first, second, ok := find_tangents(&polygon[0], vertices, &lower[0], lower_len,
				&upper[0], upper_len, query_points[i])
			if !ok { return -1 }
			answers[2 * i] = i64(first)
			answers[2 * i + 1] = i64(second)
		}
		needed := 16 * queries
		if usize(needed) > capacity || output == nil { return -2 }
		for i in 0 .. 2 * queries { put_i64(mut output, 8 * i, answers[i]) }
		return i64(needed)
	}
}
