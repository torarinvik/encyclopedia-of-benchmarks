module convex_polygon_minimax_angle_edge_insertion

const min_n = 3
const max_n = 4
const max_length = 10
const max_angles = 12

struct Point { x i64; y i64 }
struct AngleRef { a int; b int; c int; vertex int }
struct Triangle { a int; b int; c int }

fn orient(p [max_n]Point, a int, b int, c int) i64 {
	return (p[b].x - p[a].x) * (p[c].y - p[a].y) - (p[b].y - p[a].y) * (p[c].x - p[a].x)
}

fn angle_dot(p [max_n]Point, angle AngleRef) i64 {
	vertices := [3]int{angle.a, angle.b, angle.c}
	center := vertices[angle.vertex]
	mut endpoints := [2]int{}
	mut used := 0
	for i in 0 .. 3 {
		if vertices[i] != center { endpoints[used] = vertices[i]; used++ }
	}
	ux := p[endpoints[0]].x - p[center].x
	uy := p[endpoints[0]].y - p[center].y
	vx := p[endpoints[1]].x - p[center].x
	vy := p[endpoints[1]].y - p[center].y
	return ux * vx + uy * vy
}

fn angle_den(p [max_n]Point, angle AngleRef) i64 {
	vertices := [3]int{angle.a, angle.b, angle.c}
	center := vertices[angle.vertex]
	mut endpoints := [2]int{}
	mut used := 0
	for i in 0 .. 3 {
		if vertices[i] != center { endpoints[used] = vertices[i]; used++ }
	}
	ux := p[endpoints[0]].x - p[center].x
	uy := p[endpoints[0]].y - p[center].y
	vx := p[endpoints[1]].x - p[center].x
	vy := p[endpoints[1]].y - p[center].y
	return (ux * ux + uy * uy) * (vx * vx + vy * vy)
}

fn angle_cmp(p [max_n]Point, left AngleRef, right AngleRef) int {
	d1, z1 := angle_dot(p, left), angle_den(p, left)
	d2, z2 := angle_dot(p, right), angle_den(p, right)
	if d1 == 0 || d2 == 0 {
		if d1 == d2 { return 0 }
		if d1 == 0 { return if d2 > 0 { 1 } else { -1 } }
		return if d1 > 0 { -1 } else { 1 }
	}
	if (d1 < 0) != (d2 < 0) { return if d1 < 0 { 1 } else { -1 } }
	lhs, rhs := d1 * d1 * z2, d2 * d2 * z1
	if lhs == rhs { return 0 }
	if d1 > 0 { return if lhs > rhs { -1 } else { 1 } }
	return if lhs > rhs { 1 } else { -1 }
}

fn triangle_max(p [max_n]Point, t Triangle) AngleRef {
	mut v := [3]int{t.a, t.b, t.c}
	for i in 0 .. 3 {
		for j in i + 1 .. 3 {
			if v[i] > v[j] { tmp := v[i]; v[i] = v[j]; v[j] = tmp }
		}
	}
	mut best := AngleRef{v[0], v[1], v[2], 0}
	for vertex in 1 .. 3 {
		candidate := AngleRef{v[0], v[1], v[2], vertex}
		if angle_cmp(p, candidate, best) > 0 { best = candidate }
	}
	return best
}

fn triangulation_max(p [max_n]Point, triangles []Triangle) AngleRef {
	mut best := triangle_max(p, triangles[0])
	for i in 1 .. triangles.len {
		candidate := triangle_max(p, triangles[i])
		if angle_cmp(p, candidate, best) > 0 { best = candidate }
	}
	return best
}

fn angle_rank(p [max_n]Point, n int, target AngleRef) i64 {
	mut distinct_lower := [max_angles]AngleRef{}
	mut count := 0
	for a in 0 .. n {
		for b in a + 1 .. n {
			for c in b + 1 .. n {
				for vertex in 0 .. 3 {
					candidate := AngleRef{a, b, c, vertex}
					if angle_cmp(p, candidate, target) >= 0 { continue }
					mut seen := false
					for i in 0 .. count { if angle_cmp(p, candidate, distinct_lower[i]) == 0 { seen = true } }
					if !seen { distinct_lower[count] = candidate; count++ }
				}
			}
		}
	}
	return i64(count + 1)
}

fn proper_crossing(p [max_n]Point, a int, b int, c int, d int) bool {
	return orient(p, a, b, c) * orient(p, a, b, d) < 0 && orient(p, c, d, a) * orient(p, c, d, b) < 0
}

@[export: 'convex_polygon_minimax_angle_edge_insertion']
pub fn convex_polygon_minimax_angle_edge_insertion(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_length { return -1 }
		if input[0] < min_n || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(1 + 2 * n) { return -1 }
		mut p := [max_n]Point{}
		for i in 0 .. n {
			p[i] = Point{input[1 + 2 * i], input[2 + 2 * i]}
			if p[i].x < -16 || p[i].x > 16 || p[i].y < -16 || p[i].y > 16 { return -1 }
			for j in 0 .. i { if p[i].x == p[j].x && p[i].y == p[j].y { return -1 } }
		}
		mut area2 := i64(0)
		for i in 0 .. n { next := (i + 1) % n; area2 += p[i].x * p[next].y - p[i].y * p[next].x }
		if area2 == 0 { return -1 }
		orientation := if area2 > 0 { i64(1) } else { i64(-1) }
		for a in 0 .. n { for b in a + 1 .. n { for c in b + 1 .. n { if orient(p, a, b, c) == 0 { return -1 } } } }
		for edge in 0 .. n {
			next := (edge + 1) % n
			for vertex in 0 .. n {
				if vertex != edge && vertex != next && orientation * orient(p, edge, next, vertex) <= 0 { return -1 }
			}
		}
		fan := [2]Triangle{Triangle{0, 1, 2}, Triangle{0, 2, 3}}
		mut worst := if n == 3 { triangle_max(p, Triangle{0, 1, 2}) } else { triangulation_max(p, fan[:]) }
		if n == 4 {
			mut accepted := false
			for ti in 0 .. 2 {
				if accepted { break }
				vertices := [3]int{fan[ti].a, fan[ti].b, fan[ti].c}
				for vertex in 0 .. 3 {
					if accepted { break }
					candidate := AngleRef{vertices[0], vertices[1], vertices[2], vertex}
					if angle_cmp(p, candidate, worst) != 0 { continue }
					q := vertices[vertex]
					mut opposite := [2]int{}
					mut used := 0
					s := -1
					for i in 0 .. 3 { if i != vertex { opposite[used] = vertices[i]; used++ } }
					for point in 0 .. 4 { if point != vertices[0] && point != vertices[1] && point != vertices[2] { s = point } }
					if !proper_crossing(p, q, s, opposite[0], opposite[1]) { continue }
					inserted := [2]Triangle{Triangle{q, s, opposite[0]}, Triangle{q, s, opposite[1]}}
					replacement := triangulation_max(p, inserted[:])
					if angle_cmp(p, replacement, worst) < 0 { worst = replacement; accepted = true }
				}
			}
		}
		return angle_rank(p, n, worst)
	}
}
