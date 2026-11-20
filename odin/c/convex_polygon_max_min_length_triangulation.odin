package convex_polygon_max_min_length_triangulation

import "core:c"

MIN_N :: 3
MAX_N :: 6
MAX_LENGTH :: 14

Point :: struct { x, y: i64 }

orient :: proc "contextless" (a, b, c: Point) -> i64 {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
distance_squared :: proc "contextless" (a, b: Point) -> i64 {
	dx, dy := a.x-b.x, a.y-b.y
	return dx*dx+dy*dy
}
diagonal_bit :: proc "contextless" (n, a0, b0: int) -> int {
	left, right := min(a0,b0), max(a0,b0)
	bit := 0
	for first := 0; first < n; first += 1 {
		for second := first+2; second < n; second += 1 {
			if first == 0 && second == n-1 do continue
			if first == left && second == right do return bit
			bit += 1
		}
	}
	return -1
}
angle_at_least_sixty :: proc "contextless" (p, q, r: Point) -> bool {
	ux, uy := p.x-q.x, p.y-q.y
	vx, vy := r.x-q.x, r.y-q.y
	dot := ux*vx+uy*vy
	if dot <= 0 do return true
	norm_u, norm_v := ux*ux+uy*uy, vx*vx+vy*vy
	return 4*dot*dot <= norm_u*norm_v
}

greedy :: proc "contextless" (points: [MAX_N]Point, n: int) -> i64 {
	var next: [MAX_N]int
	for i := 0; i < n; i += 1 { next[i] = (i+1)%n }
	shortest := i64(513)
	for i := 0; i < n; i += 1 {
		edge := distance_squared(points[i],points[(i+1)%n])
		if edge < shortest { shortest = edge }
	}
	active, p := n, 0
	q, r := next[p], next[next[p]]
	steps := 0
	diagonal_mask := i64(0)
	for active > 3 {
		steps += 1
		if steps > 4*n do return -1
		if angle_at_least_sixty(points[p],points[q],points[r]) {
			chord := distance_squared(points[p],points[r])
			if chord < shortest { shortest = chord }
			bit := diagonal_bit(n,p,r)
			if bit < 0 do return -1
			diagonal_mask |= i64(1) << bit
			next[p] = r
			active -= 1
			q = r
			r = next[r]
		} else {
			p = q
			q = r
			r = next[r]
		}
	}
	return shortest*512+diagonal_mask
}

@(export)
convex_polygon_max_min_length_triangulation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < MIN_N || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1+2*n) do return -1
	var points: [MAX_N]Point
	for i := 0; i < n; i += 1 {
		points[i] = Point{input[1+2*i],input[2+2*i]}
		if points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8 do return -1
		for j := 0; j < i; j += 1 {
			if points[i].x == points[j].x && points[i].y == points[j].y do return -1
		}
	}
	area2: i64 = 0
	for i := 0; i < n; i += 1 {
		next := (i+1)%n
		area2 += points[i].x*points[next].y-points[i].y*points[next].x
	}
	if area2 <= 0 do return -1
	for a := 0; a < n; a += 1 {
		for b := a+1; b < n; b += 1 {
			for cidx := b+1; cidx < n; cidx += 1 {
				if orient(points[a],points[b],points[cidx]) == 0 do return -1
			}
		}
	}
	for edge := 0; edge < n; edge += 1 {
		next := (edge+1)%n
		for vertex := 0; vertex < n; vertex += 1 {
			if vertex != edge && vertex != next && orient(points[edge],points[next],points[vertex]) <= 0 do return -1
		}
	}
	return greedy(points,n)
}
