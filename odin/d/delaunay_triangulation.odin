package delaunay_triangulation

import "core:c"
MAX_POINTS :: 8
MAX_VERTICES :: 11
MAX_WORK_TRIANGLES :: 17
MAX_WORK_EDGES :: 51
MAX_TRIANGLES :: 11
MAX_OUTPUT_BYTES :: 272
CIRCUMCIRCLE_EPSILON :: 1e-4

Point :: struct { x, y: f64 }
Edge :: struct { a, b: int }
Triangle :: struct { a, b, c: int, cx, cy, radius_squared: f64 }

orient :: proc "contextless" (ax, ay, bx, by, cx, cy: i64) -> i64 {
	return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
}
incircle :: proc "contextless" (ax, ay, bx, by, cx, cy, dx, dy: i64) -> i64 {
	x1, y1 := ax-dx, ay-dy
	x2, y2 := bx-dx, by-dy
	x3, y3 := cx-dx, cy-dy
	q1, q2, q3 := x1*x1+y1*y1, x2*x2+y2*y2, x3*x3+y3*y3
	return q1*(x2*y3-y2*x3) - q2*(x1*y3-y1*x3) + q3*(x1*y2-y1*x2)
}
same_edge :: proc "contextless" (a, b: Edge) -> bool {
	return (a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a)
}
make_triangle :: proc "contextless" (points: [^]Point, a, b, c: int) -> Triangle {
	p0, p1, p2 := points[a], points[b], points[c]
	ax, ay := p1.x-p0.x, p1.y-p0.y
	bx, by := p2.x-p0.x, p2.y-p0.y
	m := p1.x*p1.x-p0.x*p0.x+p1.y*p1.y-p0.y*p0.y
	u := p2.x*p2.x-p0.x*p0.x+p2.y*p2.y-p0.y*p0.y
	scale := 1.0/(2.0*(ax*by-ay*bx))
	cx := ((p2.y-p0.y)*m+(p0.y-p1.y)*u)*scale
	cy := ((p0.x-p2.x)*m+(p1.x-p0.x)*u)*scale
	dx, dy := p0.x-cx, p0.y-cy
	return Triangle{a, b, c, cx, cy, dx*dx+dy*dy}
}
sort_indices :: proc "contextless" (a, b, c: ^int) {
	if a^ > b^ { a^, b^ = b^, a^ }
	if b^ > c^ { b^, c^ = c^, b^ }
	if a^ > b^ { a^, b^ = b^, a^ }
}
triangle_less :: proc "contextless" (a, b: Triangle) -> bool {
	if a.a != b.a { return a.a < b.a }
	if a.b != b.b { return a.b < b.b }
	return a.c < b.c
}
put_i64 :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { out[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
delaunay_triangulation :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 7 || length > 17 || values[0] < 3 || values[0] > MAX_POINTS || length != c.size_t(1+2*values[0]) do return -1
	n := int(values[0])
	ix: [MAX_POINTS]i64
	iy: [MAX_POINTS]i64
	points: [MAX_VERTICES]Point
	min_x, max_x, min_y, max_y: i64
	for i := 0; i < n; i += 1 {
		x, y := values[1+2*i], values[2+2*i]
		if x < -10 || x > 10 || y < -10 || y > 10 do return -1
		for j := 0; j < i; j += 1 { if ix[j] == x && iy[j] == y do return -1 }
		ix[i], iy[i] = x, y
		points[i] = Point{f64(x), f64(y)}
		if i == 0 { min_x, max_x, min_y, max_y = x, x, y, y }
		else { min_x = min(min_x, x); max_x = max(max_x, x); min_y = min(min_y, y); max_y = max(max_y, y) }
	}
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			for c := b+1; c < n; c += 1 { if orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0 do return -1 }
		}
	}
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			for c := b+1; c < n; c += 1 {
				for d := c+1; d < n; d += 1 { if incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0 do return -1 }
			}
		}
	}

	dmax := max(max_x-min_x, max_y-min_y)
	midx, midy := (f64(min_x)+f64(max_x))/2.0, (f64(min_y)+f64(max_y))/2.0
	s0, s1, s2 := n, n+1, n+2
	points[s0] = Point{midx-20.0*f64(dmax), midy-f64(dmax)}
	points[s1] = Point{midx, midy+20.0*f64(dmax)}
	points[s2] = Point{midx+20.0*f64(dmax), midy-f64(dmax)}
	for a := 0; a < n+3; a += 1 {
		for b := a+1; b < n+3; b += 1 {
			for c := b+1; c < n+3; c += 1 {
				area2 := (points[b].x-points[a].x)*(points[c].y-points[a].y)-(points[b].y-points[a].y)*(points[c].x-points[a].x)
				if area2 == 0 do return -1
			}
		}
	}

	current: [MAX_WORK_TRIANGLES]Triangle
	next: [MAX_WORK_TRIANGLES]Triangle
	edges: [MAX_WORK_EDGES]Edge
	current_count := 1
	current[0] = make_triangle(&points[0], s0, s1, s2)
	for p := 0; p < n; p += 1 {
		edge_count, next_count := 0, 0
		for i := 0; i < current_count; i += 1 {
			t := current[i]
			dx, dy := t.cx-points[p].x, t.cy-points[p].y
			if dx*dx+dy*dy-t.radius_squared <= CIRCUMCIRCLE_EPSILON {
				edges[edge_count], edges[edge_count+1], edges[edge_count+2] = Edge{t.a,t.b}, Edge{t.b,t.c}, Edge{t.a,t.c}
				edge_count += 3
			} else {
				if next_count >= MAX_WORK_TRIANGLES do return -1
				next[next_count] = t; next_count += 1
			}
		}
		remove: [MAX_WORK_EDGES]bool
		for i := 0; i < edge_count; i += 1 {
			for j := 0; j < edge_count; j += 1 { if i != j && same_edge(edges[i], edges[j]) { remove[i], remove[j] = true, true } }
		}
		for i := 0; i < edge_count; i += 1 {
			if !remove[i] {
				if next_count >= MAX_WORK_TRIANGLES do return -1
				next[next_count] = make_triangle(&points[0], edges[i].a, edges[i].b, p); next_count += 1
			}
		}
		for i := 0; i < next_count; i += 1 { current[i] = next[i] }
		current_count = next_count
	}
	result: [MAX_TRIANGLES]Triangle
	result_count := 0
	for i := 0; i < current_count; i += 1 {
		t := current[i]
		if t.a >= n || t.b >= n || t.c >= n do continue
		if result_count >= MAX_TRIANGLES do return -1
		sort_indices(&t.a, &t.b, &t.c)
		j := result_count; result_count += 1
		for j > 0 && triangle_less(t, result[j-1]) { result[j] = result[j-1]; j -= 1 }
		result[j] = t
	}
	if result_count == 0 do return -1
	staged: [MAX_OUTPUT_BYTES]u8
	put_i64(&staged[0], 0, i64(result_count))
	for i := 0; i < result_count; i += 1 {
		put_i64(&staged[0], 8+24*i, i64(result[i].a)); put_i64(&staged[0], 16+24*i, i64(result[i].b)); put_i64(&staged[0], 24+24*i, i64(result[i].c))
	}
	required := 8+24*result_count
	if output == nil || capacity < c.size_t(required) do return -2
	for i := 0; i < required; i += 1 { output[i] = staged[i] }
	return i64(required)
}
