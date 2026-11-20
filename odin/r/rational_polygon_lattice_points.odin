package rational_polygon_lattice_points

import "core:c"

Point :: struct { x, y: i64 }

rpl_floor_div :: proc(a, b: i64) -> i64 {
	q := a / b
	r := a % b
	if r < 0 { q -= 1 }
	return q
}

rpl_ceil_div :: proc(a, b: i64) -> i64 { return -rpl_floor_div(-a, b) }

rpl_floor_sum :: proc(n0, m0, a0, b0: i64) -> i64 {
	aq := rpl_floor_div(a0, m0)
	bq := rpl_floor_div(b0, m0)
	answer := aq*n0*(n0-1)/2+bq*n0
	a := a0-aq*m0
	b := b0-bq*m0
	n := n0
	m := m0
	for {
		if a >= m { answer += (n-1)*n*(a/m)/2; a %= m }
		if b >= m { answer += n*(b/m); b %= m }
		top := a*n+b
		if top < m { return answer }
		n = top/m
		b = top%m
		t := m
		m = a
		a = t
	}
}

rpl_edge_chunk :: proc(scale: i64, ax: i64, ay: i64, dx: i64, dy: i64,
		start: i64, columns: i64) -> i64 {
	if columns <= 0 do return 0
	aa := dy*scale
	bb := ay*dx-dy*ax
	den := scale*dx
	if den < 0 { aa = -aa; bb = -bb; den = -den }
	base := aa*start+bb
	if dx > 0 do return -rpl_floor_sum(columns,den,aa,base)
	return -rpl_floor_sum(columns,den,-aa,-base)-columns
}

rpl_inside :: proc(points: [8]Point, n: int, scale: i64, x: i64, y: i64) -> bool {
	px := x*scale
	py := y*scale
	inside := false
	for i in 0..<n {
		j := (i+1)%n
		a := points[i]
		b := points[j]
		cross := (b.x-a.x)*(py-a.y)-(b.y-a.y)*(px-a.x)
		if cross == 0 && px >= min(a.x,b.x) && px <= max(a.x,b.x) && py >= min(a.y,b.y) && py <= max(a.y,b.y) do return false
		if (a.y > py) != (b.y > py) {
			dy := b.y-a.y
			dx := b.x-a.x
			left := a.x*dy+(py-a.y)*dx
			right := px*dy
			if (dy > 0 && left > right) || (dy < 0 && left < right) do inside = !inside
		}
	}
	return inside
}

@(export)
rational_polygon_lattice_points :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 19 do return -1
	scale := input[0]
	nr := input[1]
	if scale < 2 || scale > 8 || nr < 3 || nr > 8 || length != c.size_t(2+2*nr) do return -1
	n := int(nr)
	points: [8]Point
	fractional := false
	for i in 0..<n {
		points[i] = Point{input[2+2*i], input[3+2*i]}
		if points[i].x < -32 || points[i].x > 32 || points[i].y < -32 || points[i].y > 32 do return -1
        if points[i].x < -4*scale || points[i].x > 4*scale || points[i].y < -4*scale || points[i].y > 4*scale do return -1
		if points[i].x%scale != 0 || points[i].y%scale != 0 do fractional = true
		for j in 0..<i {
			if points[i].x == points[j].x && points[i].y == points[j].y do return -1
		}
	}
	if !fractional do return -1
	area2: i64 = 0
	for i in 0..<n {
		a := points[i]
		b := points[(i+1)%n]
		area2 += a.x*b.y-a.y*b.x
	}
	if area2 == 0 do return -1
	orientation: i64 = 1
	if area2 < 0 do orientation = -1
	for i in 0..<n {
		a := points[i]
		b := points[(i+1)%n]
		for j in 0..<n {
			if j == i || j == (i+1)%n do continue
			c := points[j]
			cross := (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
			if cross*orientation <= 0 do return -1
		}
	}
	signed_count: i64 = 0
	for i in 0..<n {
		a := points[i]
		b := points[(i+1)%n]
		dx := b.x-a.x
		dy := b.y-a.y
		if dx == 0 do continue
		lo := min(a.x,b.x)
		hi := max(a.x,b.x)
		start := rpl_ceil_div(lo,scale)
		stop := rpl_ceil_div(hi,scale)
		cursor := start
		for col in int(start)..<int(stop) {
			event := false
			for k in 0..<n { if points[k].x == i64(col)*scale do event = true }
			if event {
				signed_count += rpl_edge_chunk(scale,a.x,a.y,dx,dy,cursor,i64(col)-cursor)
				cursor = i64(col)+1
			}
		}
		signed_count += rpl_edge_chunk(scale,a.x,a.y,dx,dy,cursor,stop-cursor)
	}
	for i in 0..<n {
		if points[i].x%scale != 0 do continue
		first := true
		for j in 0..<i { if points[j].x == points[i].x do first = false }
		if !first do continue
		x := points[i].x/scale
		count: i64 = 0
		for y in -4..4 { if rpl_inside(points,n,scale,x,i64(y)) do count += 1 }
		signed_count += orientation*count
	}
	result := signed_count*orientation
	if result < 0 do return -1
	return result
}
