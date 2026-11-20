module max_min_triangle_height_triangulation

const min_n = 3
const max_n = 5
const max_length = 12
const dp_size = 10

struct Point {
	x i64
	y i64
}
struct Score {
	num i64
	den i64
}
struct Cell {
	minimum Score
	count int
	valid bool
	split int
}
struct Triangle {
	a int
	b int
	c int
}
struct Triangles {
	items [3]Triangle
	count int
}
struct Objective {
	minimum Score
	count int
}

fn orient(a Point, b Point, c Point) i64 {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}

fn gcd64(a0 i64, b0 i64) i64 {
	mut a := a0
	mut b := b0
	for b != 0 {
		r := a % b
		a = b
		b = r
	}
	return a
}

fn fraction(num i64, den i64) Score {
	divisor := gcd64(num, den)
	return Score{num: num/divisor, den: den/divisor}
}

fn compare(a Score, b Score) int {
	left := a.num*b.den
	right := b.num*a.den
	if left < right { return -1 }
	if left > right { return 1 }
	return 0
}

fn triangle_score(points [max_n]Point, n int, a int, b int, c int) Score {
	p := points[a % n]
	q := points[b % n]
	r := points[c % n]
	area := orient(p, q, r)
	if area < 0 { area = -area }
	lengths := [3]i64{
		(p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
		(q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
		(r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y),
	}
	mut best := fraction(area*area, lengths[0])
	for i in 1 .. 3 {
		candidate := fraction(area*area, lengths[i])
		if compare(candidate, best) < 0 { best = candidate }
	}
	return best
}

fn join(left Cell, right Cell, triangle Score) Objective {
	mut out := Objective{minimum: triangle, count: 1}
	children := [2]Cell{left, right}
	for child in children {
		if !child.valid { continue }
		cmp := compare(child.minimum, out.minimum)
		if cmp < 0 { out.minimum = child.minimum; out.count = child.count }
		else if cmp == 0 { out.count += child.count }
	}
	return out
}

fn better(candidate Objective, current Objective) bool {
	cmp := compare(candidate.minimum, current.minimum)
	return cmp > 0 || (cmp == 0 && candidate.count < current.count)
}

fn evaluate(points [max_n]Point, n int, triangles Triangles) Objective {
	first := triangles.items[0]
	mut out := Objective{minimum: triangle_score(points, n, first.a, first.b, first.c), count: 1}
	for i in 1 .. triangles.count {
		t := triangles.items[i]
		score := triangle_score(points, n, t.a, t.b, t.c)
		cmp := compare(score, out.minimum)
		if cmp < 0 { out.minimum = score; out.count = 1 }
		else if cmp == 0 { out.count++ }
	}
	return out
}

fn collect(start int, finish int, table [dp_size * dp_size]Cell, n int, mut output Triangles) {
	if finish-start < 2 { return }
	middle := table[start*dp_size+finish].split
	output.items[output.count] = Triangle{a: start%n, b: middle%n, c: finish%n}
	output.count++
	collect(start, middle, table, n, mut output)
	collect(middle, finish, table, n, mut output)
}

fn has_edge(triangles Triangles, left int, right int) bool {
	for i in 0 .. triangles.count {
		t := triangles.items[i]
		pairs := [3][2]int{{t.a,t.b},{t.b,t.c},{t.c,t.a}}
		for pair in pairs {
			a := pair[0]
			b := pair[1]
			if a > b { temp := a; a = b; b = temp }
			if a == left && b == right { return true }
		}
	}
	return false
}

fn solve(points [max_n]Point, n int) i64 {
	mut table := [dp_size * dp_size]Cell{}
	if n > 3 {
		for span in 2 .. n-1 {
			for start in 0 .. n {
				finish := start + span
				mut found := false
				mut best := Objective{minimum: Score{num: 0, den: 1}, count: 0}
				mut best_middle := 0
				for middle in start+1 .. finish {
					candidate := join(table[start*dp_size+middle], table[middle*dp_size+finish],
						triangle_score(points, n, start, middle, finish))
					if !found || better(candidate, best) {
						found = true
						best = candidate
						best_middle = middle
					}
				}
				table[start*dp_size+finish] = Cell{minimum: best.minimum, count: best.count,
					valid: true, split: best_middle}
			}
		}
	}
	mut current := Triangles{}
	for middle in 1 .. n-1 {
		current.items[current.count] = Triangle{a: 0, b: middle, c: middle+1}
		current.count++
	}
	mut current_value := evaluate(points, n, current)
	mut improvements := 0
	for {
		mut changed := false
		for left in 0 .. n {
			if changed { break }
			for right in left+2 .. n {
				if left == 0 && right == n-1 { continue }
				if has_edge(current, left, right) { continue }
				mut candidate := Triangles{}
				collect(left, right, table, n, mut candidate)
				collect(right, left+n, table, n, mut candidate)
				value := evaluate(points, n, candidate)
				if better(value, current_value) {
					current = candidate
					current_value = value
					improvements++
					if improvements > 30 { return -1 }
					changed = true
					break
				}
			}
		}
		if !changed { return current_value.minimum.num*513 + current_value.minimum.den }
	}
	return -1
}

@[export: 'max_min_triangle_height_triangulation']
pub fn max_min_triangle_height_triangulation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_length { return -1 }
		if input[0] < min_n || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(1+2*n) { return -1 }
		mut points := [max_n]Point{}
		for i in 0 .. n {
			points[i] = Point{x: input[1+2*i], y: input[2+2*i]}
			if points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8 { return -1 }
			for j in 0 .. i {
				if points[i].x == points[j].x && points[i].y == points[j].y { return -1 }
			}
		}
		mut area2 := i64(0)
		for i in 0 .. n {
			next := (i+1)%n
			area2 += points[i].x*points[next].y-points[i].y*points[next].x
		}
		if area2 <= 0 { return -1 }
		for a in 0 .. n {
			for b in a+1 .. n {
				for cidx in b+1 .. n {
					if orient(points[a], points[b], points[cidx]) == 0 { return -1 }
				}
			}
		}
		for edge in 0 .. n {
			next := (edge+1)%n
			for v in 0 .. n {
				if v != edge && v != next && orient(points[edge], points[next], points[v]) <= 0 { return -1 }
			}
		}
		return solve(points, n)
	}
}
