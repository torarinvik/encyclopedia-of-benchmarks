module minkowski_sum_convex_polygons

const max_vertices = 32
const max_input = 131
const max_coord = i64(1000000)

struct Point { x i64; y i64 }

fn cross(a Point, b Point) i64 { return a.x * b.y - a.y * b.x }
fn edge(p &Point, n int, i int) Point {
	unsafe {
		next := (i + 1) % n
		return Point{ x: p[next].x - p[i].x, y: p[next].y - p[i].y }
	}
}
fn half(v Point) int { return if v.y > 0 || (v.y == 0 && v.x >= 0) { 0 } else { 1 } }
fn angle_compare(a Point, b Point) int {
	ha := half(a); hb := half(b)
	if ha != hb { if ha < hb { return -1 }; return 1 }
	turn := cross(a, b)
	if turn > 0 { return -1 }
	if turn < 0 { return 1 }
	return 0
}
fn valid_polygon(p &Point, n int) bool {
	mut wraps := 0
	for i in 0 .. n {
		a := edge(p, n, i); b := edge(p, n, (i + 1) % n)
		if (a.x == 0 && a.y == 0) || cross(a, b) <= 0 { return false }
		if angle_compare(b, a) < 0 { wraps++ }
	}
	return wraps == 1
}
fn rotate_lowest(mut p &Point, n int) {
	unsafe {
		mut first := 0
		for i in 1 .. n { if p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x) { first = i } }
		mut tmp := [max_vertices]Point{init: Point{}}
		for i in 0 .. n { tmp[i] = p[(first + i) % n] }
		for i in 0 .. n { p[i] = tmp[i] }
	}
}
fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for b in 0 .. 8 { output[offset + b] = u8((bits >> (8 * b)) & 255) }
	}
}

@[export: 'minkowski_sum_convex_polygons']
pub fn minkowski_sum_convex_polygons(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 14 || n > usize(max_input) || v[0] < 3 || v[0] > i64(max_vertices) || v[1] < 3 || v[1] > i64(max_vertices) { return -1 }
		pn := int(v[0]); qn := int(v[1])
		if n != usize(2 + 2 * pn + 2 * qn) { return -1 }
		mut p := [max_vertices]Point{init: Point{}}
		mut q := [max_vertices]Point{init: Point{}}
		mut sums := [2 * max_vertices]Point{init: Point{}}
		mut at := 2
		for i in 0 .. pn {
			p[i] = Point{ x: v[at], y: v[at + 1] }; at += 2
			if p[i].x < -max_coord || p[i].x > max_coord || p[i].y < -max_coord || p[i].y > max_coord { return -1 }
		}
		for i in 0 .. qn {
			q[i] = Point{ x: v[at], y: v[at + 1] }; at += 2
			if q[i].x < -max_coord || q[i].x > max_coord || q[i].y < -max_coord || q[i].y > max_coord { return -1 }
		}
		if !valid_polygon(&p[0], pn) || !valid_polygon(&q[0], qn) { return -1 }
		rotate_lowest(mut p[0], pn); rotate_lowest(mut q[0], qn)
		mut i := 0; mut j := 0; mut count := 0
		for i < pn || j < qn {
			sums[count] = Point{ x: p[i % pn].x + q[j % qn].x, y: p[i % pn].y + q[j % qn].y }; count++
			if i == pn { j++; continue }
			if j == qn { i++; continue }
			order := angle_compare(edge(&p[0], pn, i), edge(&q[0], qn, j))
			if order <= 0 { i++ }
			if order >= 0 { j++ }
		}
		needed := (1 + 2 * count) * 8
		if usize(needed) > capacity || output == nil { return -2 }
		put_i64(mut output, 0, i64(count))
		for k in 0 .. count { put_i64(mut output, 8 + 16 * k, sums[k].x); put_i64(mut output, 16 + 16 * k, sums[k].y) }
		return i64(needed)
	}
}
