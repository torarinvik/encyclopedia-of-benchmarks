module convex_polygon_max_min_length_triangulation

const min_n = 3
const max_n = 6
const max_length = 14

struct Point {
	x i64
	y i64
}

fn orient(a Point, b Point, c Point) i64 {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}

fn distance_squared(a Point, b Point) i64 {
	dx := a.x-b.x
	dy := a.y-b.y
	return dx*dx+dy*dy
}

fn diagonal_bit(n int, a0 int, b0 int) int {
	left := min(a0, b0)
	right := max(a0, b0)
	mut bit := 0
	for first in 0 .. n {
		for second in first+2 .. n {
			if first == 0 && second == n-1 { continue }
			if first == left && second == right { return bit }
			bit++
		}
	}
	return -1
}

fn angle_at_least_sixty(p Point, q Point, r Point) bool {
	ux := p.x-q.x
	uy := p.y-q.y
	vx := r.x-q.x
	vy := r.y-q.y
	dot := ux*vx+uy*vy
	if dot <= 0 { return true }
	norm_u := ux*ux+uy*uy
	norm_v := vx*vx+vy*vy
	return 4*dot*dot <= norm_u*norm_v
}

fn greedy(points [max_n]Point, n int) i64 {
	mut next := [max_n]int{}
	for i in 0 .. n { next[i] = (i+1)%n }
	mut shortest := i64(513)
	for i in 0 .. n {
		shortest = min(shortest, distance_squared(points[i], points[(i+1)%n]))
	}
	mut active := n
	mut p := 0
	mut q := next[p]
	mut r := next[q]
	mut steps := 0
	mut diagonal_mask := i64(0)
	for active > 3 {
		steps++
		if steps > 4*n { return -1 }
		if angle_at_least_sixty(points[p], points[q], points[r]) {
			shortest = min(shortest, distance_squared(points[p], points[r]))
			bit := diagonal_bit(n, p, r)
			if bit < 0 { return -1 }
			diagonal_mask += i64(1) << bit
			next[p] = r
			active--
			q = r
			r = next[r]
		} else {
			p = q
			q = r
			r = next[r]
		}
	}
	return shortest*512 + diagonal_mask
}

@[export: 'convex_polygon_max_min_length_triangulation']
pub fn convex_polygon_max_min_length_triangulation(input &i64, length usize) i64 {
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
				for c in b+1 .. n {
					if orient(points[a], points[b], points[c]) == 0 { return -1 }
				}
			}
		}
		for edge in 0 .. n {
			next := (edge+1)%n
			for vertex in 0 .. n {
				if vertex != edge && vertex != next && orient(points[edge], points[next], points[vertex]) <= 0 { return -1 }
			}
		}
		return greedy(points, n)
	}
}
