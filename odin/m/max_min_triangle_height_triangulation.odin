package max_min_triangle_height_triangulation

import "core:c"

MIN_N :: 3
MAX_N :: 5
MAX_LENGTH :: 12
DP_SIZE :: 10

Point :: struct { x, y: i64 }
Score :: struct { num, den: i64 }
Cell :: struct { minimum: Score, count: int, valid: bool, split: int }
Triangle :: struct { a, b, c: int }
Triangles :: struct { items: [3]Triangle, count: int }
Objective :: struct { minimum: Score, count: int }

gcd64 :: proc "contextless" (a0, b0: i64) -> i64 {
	a, b := a0, b0
	for b != 0 {
		r := a % b
		a = b
		b = r
	}
	return a
}

orient :: proc "contextless" (a, b, c: Point) -> i64 {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}

fraction :: proc "contextless" (num, den: i64) -> Score {
	divisor := gcd64(num, den)
	return Score{num/divisor, den/divisor}
}

compare :: proc "contextless" (a, b: Score) -> int {
	left, right := a.num*b.den, b.num*a.den
	if left < right do return -1
	if left > right do return 1
	return 0
}

triangle_score :: proc "contextless" (points: [MAX_N]Point, n, a, b, c: int) -> Score {
	p, q, r := points[a%n], points[b%n], points[c%n]
	area := orient(p, q, r)
	if area < 0 { area = -area }
	lengths := [3]i64{
		(p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
		(q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
		(r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y),
	}
	best := fraction(area*area, lengths[0])
	for i := 1; i < 3; i += 1 {
		candidate := fraction(area*area, lengths[i])
		if compare(candidate, best) < 0 { best = candidate }
	}
	return best
}

join :: proc "contextless" (left, right: Cell, triangle: Score) -> Objective {
	out := Objective{triangle, 1}
	children := [2]Cell{left, right}
	for i := 0; i < 2; i += 1 {
		child := children[i]
		if !child.valid do continue
		cmp := compare(child.minimum, out.minimum)
		if cmp < 0 { out.minimum = child.minimum; out.count = child.count }
		else if cmp == 0 { out.count += child.count }
	}
	return out
}

better :: proc "contextless" (candidate, current: Objective) -> bool {
	cmp := compare(candidate.minimum, current.minimum)
	return cmp > 0 || (cmp == 0 && candidate.count < current.count)
}

evaluate :: proc "contextless" (points: [MAX_N]Point, n: int, triangles: Triangles) -> Objective {
	first := triangles.items[0]
	out := Objective{triangle_score(points, n, first.a, first.b, first.c), 1}
	for i := 1; i < triangles.count; i += 1 {
		t := triangles.items[i]
		score := triangle_score(points, n, t.a, t.b, t.c)
		cmp := compare(score, out.minimum)
		if cmp < 0 { out.minimum = score; out.count = 1 }
		else if cmp == 0 { out.count += 1 }
	}
	return out
}

collect :: proc "contextless" (start, end: int, table: [DP_SIZE*DP_SIZE]Cell,
					 n: int, out: ^Triangles) {
	if end-start < 2 do return
	middle := table[start*DP_SIZE+end].split
	out.items[out.count] = Triangle{start%n, middle%n, end%n}
	out.count += 1
	collect(start, middle, table, n, out)
	collect(middle, end, table, n, out)
}

has_edge :: proc "contextless" (triangles: Triangles, left, right: int) -> bool {
	for i := 0; i < triangles.count; i += 1 {
		t := triangles.items[i]
		pairs := [3][2]int{{t.a,t.b},{t.b,t.c},{t.c,t.a}}
		for j := 0; j < 3; j += 1 {
			a, b := pairs[j][0], pairs[j][1]
			if a > b { a, b = b, a }
			if a == left && b == right do return true
		}
	}
	return false
}

solve :: proc "contextless" (points: [MAX_N]Point, n: int) -> i64 {
	var table: [DP_SIZE*DP_SIZE]Cell
	for span := 2; span <= n-2; span += 1 {
		for start := 0; start < n; start += 1 {
			end := start+span
			best := Objective{Score{0,1},0}
			best_middle := -1
			for middle := start+1; middle < end; middle += 1 {
				candidate := join(table[start*DP_SIZE+middle],table[middle*DP_SIZE+end],
					triangle_score(points,n,start,middle,end))
				if best_middle < 0 || better(candidate,best) { best=candidate; best_middle=middle }
			}
			table[start*DP_SIZE+end] = Cell{best.minimum,best.count,true,best_middle}
		}
	}
	var current: Triangles
	for middle := 1; middle < n-1; middle += 1 {
		current.items[current.count] = Triangle{0,middle,middle+1}
		current.count += 1
	}
	current_value := evaluate(points,n,current)
	improvements := 0
	for {
		changed := false
		for left := 0; left < n && !changed; left += 1 {
			for right := left+2; right < n; right += 1 {
				if left == 0 && right == n-1 do continue
				if has_edge(current,left,right) do continue
				var candidate: Triangles
				collect(left,right,table,n,&candidate)
				collect(right,left+n,table,n,&candidate)
				value := evaluate(points,n,candidate)
				if better(value,current_value) {
					current=candidate; current_value=value; improvements += 1
					if improvements > 30 do return -1
					changed=true
					break
				}
			}
		}
		if !changed do return current_value.minimum.num*513+current_value.minimum.den
	}
}

@(export)
max_min_triangle_height_triangulation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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
	for a := 0; a < n; a += 1 { for b := a+1; b < n; b += 1 { for cidx := b+1; cidx < n; cidx += 1 {
		if orient(points[a],points[b],points[cidx]) == 0 do return -1
	}}}
	for edge := 0; edge < n; edge += 1 {
		next := (edge+1)%n
		for v := 0; v < n; v += 1 {
			if v != edge && v != next && orient(points[edge],points[next],points[v]) <= 0 do return -1
		}
	}
	return solve(points,n)
}
