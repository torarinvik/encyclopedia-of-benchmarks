module delaunay_triangulation

const max_points = 8
const max_vertices = 11
const max_work_triangles = 17
const max_work_edges = 51
const max_triangles = 11
const max_output_bytes = 272
const circumcircle_epsilon = 0.0001

struct DelaunayPoint { x f64; y f64 }
struct DelaunayEdge { a int; b int }
struct DelaunayTriangle { a int; b int; c int; cx f64; cy f64; radius_squared f64 }

struct DelaunayContext {
	ix [max_points]i64
	iy [max_points]i64
	points [max_vertices]DelaunayPoint
	current [max_work_triangles]DelaunayTriangle
	next [max_work_triangles]DelaunayTriangle
	edges [max_work_edges]DelaunayEdge
	result [max_triangles]DelaunayTriangle
	mut:
	result_count int
}

fn delaunay_orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
}
fn delaunay_incircle(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) i64 {
	x1, y1 := ax-dx, ay-dy
	x2, y2 := bx-dx, by-dy
	x3, y3 := cx-dx, cy-dy
	q1, q2, q3 := x1*x1+y1*y1, x2*x2+y2*y2, x3*x3+y3*y3
	return q1*(x2*y3-y2*x3)-q2*(x1*y3-y1*x3)+q3*(x1*y2-y1*x2)
}
fn delaunay_same_edge(a DelaunayEdge, b DelaunayEdge) bool {
	return (a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a)
}
fn delaunay_make_triangle(points [max_vertices]DelaunayPoint, a int, b int, c int) DelaunayTriangle {
	p0, p1, p2 := points[a], points[b], points[c]
	ax, ay, bx, by := p1.x-p0.x, p1.y-p0.y, p2.x-p0.x, p2.y-p0.y
	m := p1.x*p1.x-p0.x*p0.x+p1.y*p1.y-p0.y*p0.y
	u := p2.x*p2.x-p0.x*p0.x+p2.y*p2.y-p0.y*p0.y
	scale := 1.0/(2.0*(ax*by-ay*bx))
	cx := ((p2.y-p0.y)*m+(p0.y-p1.y)*u)*scale
	cy := ((p0.x-p2.x)*m+(p1.x-p0.x)*u)*scale
	dx, dy := p0.x-cx, p0.y-cy
	return DelaunayTriangle{a, b, c, cx, cy, dx*dx+dy*dy}
}
fn delaunay_triangle_less(a DelaunayTriangle, b DelaunayTriangle) bool {
	if a.a != b.a { return a.a < b.a }
	if a.b != b.b { return a.b < b.b }
	return a.c < b.c
}
fn delaunay_put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits & 255) }; bits >>= 8 }
}

fn delaunay_triangulation_impl(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 7 || length > 17 || values[0] < 3 || values[0] > i64(max_points) || length != usize(1+2*values[0]) { return -1 }
		n := int(values[0])
		mut ctx := DelaunayContext{}
		mut min_x, mut max_x, mut min_y, mut max_y := i64(0), i64(0), i64(0), i64(0)
		for i in 0 .. n {
			x, y := values[1+2*i], values[2+2*i]
			if x < -10 || x > 10 || y < -10 || y > 10 { return -1 }
			for j in 0 .. i { if ctx.ix[j] == x && ctx.iy[j] == y { return -1 } }
			ctx.ix[i], ctx.iy[i] = x, y
			ctx.points[i] = DelaunayPoint{f64(x), f64(y)}
			if i == 0 { min_x, max_x, min_y, max_y = x, x, y, y }
			else { min_x = min(min_x,x); max_x = max(max_x,x); min_y = min(min_y,y); max_y = max(max_y,y) }
		}
		for a in 0 .. n { for b in a+1 .. n { for c in b+1 .. n {
			if delaunay_orient(ctx.ix[a],ctx.iy[a],ctx.ix[b],ctx.iy[b],ctx.ix[c],ctx.iy[c]) == 0 { return -1 }
		} } }
		for a in 0 .. n { for b in a+1 .. n { for c in b+1 .. n { for d in c+1 .. n {
			if delaunay_incircle(ctx.ix[a],ctx.iy[a],ctx.ix[b],ctx.iy[b],ctx.ix[c],ctx.iy[c],ctx.ix[d],ctx.iy[d]) == 0 { return -1 }
		} } } }

		dmax := max(max_x-min_x, max_y-min_y)
		midx, midy := (f64(min_x)+f64(max_x))/2.0, (f64(min_y)+f64(max_y))/2.0
		s0, s1, s2 := n, n+1, n+2
		ctx.points[s0] = DelaunayPoint{midx-20.0*f64(dmax), midy-f64(dmax)}
		ctx.points[s1] = DelaunayPoint{midx, midy+20.0*f64(dmax)}
		ctx.points[s2] = DelaunayPoint{midx+20.0*f64(dmax), midy-f64(dmax)}
		for a in 0 .. n+3 { for b in a+1 .. n+3 { for c in b+1 .. n+3 {
			area2 := (ctx.points[b].x-ctx.points[a].x)*(ctx.points[c].y-ctx.points[a].y)-(ctx.points[b].y-ctx.points[a].y)*(ctx.points[c].x-ctx.points[a].x)
			if area2 == 0.0 { return -1 }
		} } }
		mut current_count := 1
		ctx.current[0] = delaunay_make_triangle(ctx.points, s0, s1, s2)
		for p in 0 .. n {
			mut edge_count, mut next_count := 0, 0
			for i in 0 .. current_count {
				t := ctx.current[i]
				dx, dy := t.cx-ctx.points[p].x, t.cy-ctx.points[p].y
				if dx*dx+dy*dy-t.radius_squared <= circumcircle_epsilon {
					ctx.edges[edge_count], ctx.edges[edge_count+1], ctx.edges[edge_count+2] = DelaunayEdge{t.a,t.b}, DelaunayEdge{t.b,t.c}, DelaunayEdge{t.a,t.c}
					edge_count += 3
				} else {
					if next_count >= max_work_triangles { return -1 }
					ctx.next[next_count] = t
					next_count++
				}
			}
			mut remove := [max_work_edges]bool{}
			for i in 0 .. edge_count { for j in 0 .. edge_count {
				if i != j && delaunay_same_edge(ctx.edges[i], ctx.edges[j]) { remove[i], remove[j] = true, true }
			} }
			for i in 0 .. edge_count {
				if !remove[i] {
					if next_count >= max_work_triangles { return -1 }
					ctx.next[next_count] = delaunay_make_triangle(ctx.points, ctx.edges[i].a, ctx.edges[i].b, p)
					next_count++
				}
			}
			for i in 0 .. next_count { ctx.current[i] = ctx.next[i] }
			current_count = next_count
		}
		for i in 0 .. current_count {
			mut t := ctx.current[i]
			if t.a >= n || t.b >= n || t.c >= n { continue }
			if ctx.result_count >= max_triangles { return -1 }
			if t.a > t.b { t.a, t.b = t.b, t.a }; if t.b > t.c { t.b, t.c = t.c, t.b }; if t.a > t.b { t.a, t.b = t.b, t.a }
			mut j := ctx.result_count
			ctx.result_count++
			for j > 0 && delaunay_triangle_less(t, ctx.result[j-1]) { ctx.result[j] = ctx.result[j-1]; j-- }
			ctx.result[j] = t
		}
		if ctx.result_count == 0 { return -1 }
		mut staged := [max_output_bytes]u8{}
		delaunay_put_i64(mut &staged[0], 0, i64(ctx.result_count))
		for i in 0 .. ctx.result_count {
			delaunay_put_i64(mut &staged[0], 8+24*i, i64(ctx.result[i].a))
			delaunay_put_i64(mut &staged[0], 16+24*i, i64(ctx.result[i].b))
			delaunay_put_i64(mut &staged[0], 24+24*i, i64(ctx.result[i].c))
		}
		required := 8+24*ctx.result_count
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}

@[export: 'delaunay_triangulation']
pub fn delaunay_triangulation(values &i64, length usize, mut output &u8, capacity usize) i64 {
	return delaunay_triangulation_impl(values, length, mut output, capacity)
}
