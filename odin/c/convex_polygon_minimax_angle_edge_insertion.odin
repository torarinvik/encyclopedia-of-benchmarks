package convex_polygon_minimax_angle_edge_insertion

import "core:c"

MIN_N :: 3
MAX_N :: 4
MAX_LENGTH :: 10
MAX_ANGLES :: 12

Point :: struct { x, y: i64 }
Angle_Ref :: struct { a, b, c, vertex: int }
Triangle :: struct { a, b, c: int }

orient :: proc(p: [^]Point, a, b, c0: int) -> i64 {
	return (p[b].x - p[a].x) * (p[c0].y - p[a].y) - (p[b].y - p[a].y) * (p[c0].x - p[a].x)
}

angle_dot :: proc(p: [^]Point, angle: Angle_Ref) -> i64 {
	vertices := [3]int{angle.a, angle.b, angle.c}
	center := vertices[angle.vertex]
	endpoints: [2]int
	used := 0
	for i in 0 ..< 3 {
		if vertices[i] != center {
			endpoints[used] = vertices[i]
			used += 1
		}
	}
	ux := p[endpoints[0]].x - p[center].x
	uy := p[endpoints[0]].y - p[center].y
	vx := p[endpoints[1]].x - p[center].x
	vy := p[endpoints[1]].y - p[center].y
	return ux*vx + uy*vy
}

angle_den :: proc(p: [^]Point, angle: Angle_Ref) -> i64 {
	vertices := [3]int{angle.a, angle.b, angle.c}
	center := vertices[angle.vertex]
	endpoints: [2]int
	used := 0
	for i in 0 ..< 3 {
		if vertices[i] != center {
			endpoints[used] = vertices[i]
			used += 1
		}
	}
	ux := p[endpoints[0]].x - p[center].x
	uy := p[endpoints[0]].y - p[center].y
	vx := p[endpoints[1]].x - p[center].x
	vy := p[endpoints[1]].y - p[center].y
	return (ux*ux + uy*uy) * (vx*vx + vy*vy)
}

angle_cmp :: proc(p: [^]Point, left, right: Angle_Ref) -> int {
	d1, z1 := angle_dot(p, left), angle_den(p, left)
	d2, z2 := angle_dot(p, right), angle_den(p, right)
	if d1 == 0 || d2 == 0 {
		if d1 == d2 do return 0
		if d1 == 0 do return if d2 > 0 then 1 else -1
		return if d1 > 0 then -1 else 1
	}
	if (d1 < 0) != (d2 < 0) do return if d1 < 0 then 1 else -1
	lhs, rhs := d1*d1*z2, d2*d2*z1
	if lhs == rhs do return 0
	if d1 > 0 do return if lhs > rhs then -1 else 1
	return if lhs > rhs then 1 else -1
}

triangle_max :: proc(p: [^]Point, t: Triangle) -> Angle_Ref {
	v := [3]int{t.a, t.b, t.c}
	for i in 0 ..< 3 {
		for j in i+1 ..< 3 {
			if v[i] > v[j] { v[i], v[j] = v[j], v[i] }
		}
	}
	best := Angle_Ref{v[0], v[1], v[2], 0}
	for vertex in 1 ..< 3 {
		candidate := Angle_Ref{v[0], v[1], v[2], vertex}
		if angle_cmp(p, candidate, best) > 0 do best = candidate
	}
	return best
}

triangulation_max :: proc(p: [^]Point, triangles: [^]Triangle, count: int) -> Angle_Ref {
	best := triangle_max(p, triangles[0])
	for i in 1 ..< count {
		candidate := triangle_max(p, triangles[i])
		if angle_cmp(p, candidate, best) > 0 do best = candidate
	}
	return best
}

angle_rank :: proc(p: [^]Point, n: int, target: Angle_Ref) -> i64 {
	distinct_lower: [MAX_ANGLES]Angle_Ref
	distinct_count := 0
	for a in 0 ..< n {
		for b in a+1 ..< n {
			for c0 in b+1 ..< n {
				for vertex in 0 ..< 3 {
					candidate := Angle_Ref{a, b, c0, vertex}
					if angle_cmp(p, candidate, target) >= 0 do continue
					seen := false
					for i in 0 ..< distinct_count {
						if angle_cmp(p, candidate, distinct_lower[i]) == 0 do seen = true
					}
					if !seen {
						distinct_lower[distinct_count] = candidate
						distinct_count += 1
					}
				}
			}
		}
	}
	return i64(distinct_count + 1)
}

proper_crossing :: proc(p: [^]Point, a, b, c0, d: int) -> bool {
	return orient(p, a, b, c0)*orient(p, a, b, d) < 0 && orient(p, c0, d, a)*orient(p, c0, d, b) < 0
}

@(export)
convex_polygon_minimax_angle_edge_insertion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH do return -1
	if input[0] < i64(MIN_N) || input[0] > i64(MAX_N) do return -1
	n := int(input[0])
	if length != c.size_t(1 + 2*n) do return -1
	var points: [MAX_N]Point
	for i in 0 ..< n {
		points[i] = Point{input[1+2*i], input[2+2*i]}
		if points[i].x < -16 || points[i].x > 16 || points[i].y < -16 || points[i].y > 16 do return -1
		for j in 0 ..< i {
			if points[i].x == points[j].x && points[i].y == points[j].y do return -1
		}
	}
	area2: i64 = 0
	for i in 0 ..< n {
		next := (i+1) % n
		area2 += points[i].x*points[next].y - points[i].y*points[next].x
	}
	if area2 == 0 do return -1
	orientation := if area2 > 0 then i64(1) else i64(-1)
	for a in 0 ..< n {
		for b in a+1 ..< n {
			for c0 in b+1 ..< n {
				if orient(&points[0], a, b, c0) == 0 do return -1
			}
		}
	}
	for edge in 0 ..< n {
		next := (edge+1) % n
		for vertex in 0 ..< n {
			if vertex != edge && vertex != next && orientation*orient(&points[0], edge, next, vertex) <= 0 do return -1
		}
	}
	var fan: [2]Triangle = {Triangle{0, 1, 2}, Triangle{0, 2, 3}}
	worst := if n == 3 then triangle_max(&points[0], Triangle{0, 1, 2}) else triangulation_max(&points[0], &fan[0], 2)
	if n == 4 {
		accepted := false
		for ti in 0 ..< 2 {
			if accepted do break
			vertices := [3]int{fan[ti].a, fan[ti].b, fan[ti].c}
			for vertex in 0 ..< 3 {
				if accepted do break
				candidate := Angle_Ref{vertices[0], vertices[1], vertices[2], vertex}
				if angle_cmp(&points[0], candidate, worst) != 0 do continue
				q := vertices[vertex]
				opposite: [2]int
				used, s := 0, -1
				for i in 0 ..< 3 {
					if i != vertex { opposite[used] = vertices[i]; used += 1 }
				}
				for point in 0 ..< 4 {
					if point != vertices[0] && point != vertices[1] && point != vertices[2] do s = point
				}
				if !proper_crossing(&points[0], q, s, opposite[0], opposite[1]) do continue
				inserted := [2]Triangle{Triangle{q, s, opposite[0]}, Triangle{q, s, opposite[1]}}
				replacement := triangulation_max(&points[0], &inserted[0], 2)
				if angle_cmp(&points[0], replacement, worst) < 0 { worst = replacement; accepted = true }
			}
		}
	}
	return angle_rank(&points[0], n, worst)
}
