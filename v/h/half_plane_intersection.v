module half_plane_intersection

const max_lines = 16
const max_input = 37
const box_limit = i64(256)

struct Halfplane { a i64; b i64; c i64 }
struct Point { x i64; y i64; den i64 }

fn abs64(x i64) i64 { return if x < 0 { -x } else { x } }
fn gcd64(a0 i64, b0 i64) i64 {
	mut a := abs64(a0); mut b := abs64(b0)
	for b != 0 { r := a % b; a = b; b = r }
	return a
}
fn angle_half(h Halfplane) int { return if h.b > 0 || (h.b == 0 && h.a >= 0) { 0 } else { 1 } }
fn line_compare(x Halfplane, y Halfplane) int {
	hx := angle_half(x); hy := angle_half(y)
	if hx != hy { return if hx < hy { -1 } else { 1 } }
	turn := x.a * y.b - x.b * y.a
	if turn != 0 { return if turn > 0 { -1 } else { 1 } }
	if x.c < y.c { return -1 }
	if x.c > y.c { return 1 }
	return 0
}
fn intersect(x Halfplane, y Halfplane, mut p Point) bool {
	mut det := x.a * y.b - y.a * x.b
	if det == 0 { return false }
	mut xn := x.c * y.b - x.b * y.c
	mut yn := x.a * y.c - x.c * y.a
	if det < 0 { det = -det; xn = -xn; yn = -yn }
	g := gcd64(gcd64(xn, yn), det)
	p = Point{ x: xn / g, y: yn / g, den: det / g }
	return true
}
fn outside(h Halfplane, p Point) bool { return h.a * p.x + h.b * p.y > h.c * p.den }
fn same_point(x Point, y Point) bool { return x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den }
fn orient(a Point, b Point, c Point) i64 {
	dx1 := b.x * a.den - a.x * b.den; dy1 := b.y * a.den - a.y * b.den
	dx2 := c.x * b.den - b.x * c.den; dy2 := c.y * b.den - b.y * c.den
	return dx1 * dy2 - dy1 * dx2
}
fn less_yx(a Point, b Point) bool {
	y1 := a.y * b.den; y2 := b.y * a.den
	if y1 != y2 { return y1 < y2 }
	return a.x * b.den < b.x * a.den
}
fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for b in 0 .. 8 { output[offset + b] = u8((bits >> (8 * b)) & 255) }
	}
}

@[export: 'half_plane_intersection']
pub fn half_plane_intersection(values &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || n < 1 || n > max_input || values[0] < 0 || values[0] > 12 { return -1 }
		count := int(values[0])
		if n != usize(1 + 3 * count) { return -1 }
		mut lines := [max_lines]Halfplane{init: Halfplane{}}
		mut queue := [max_lines]Halfplane{init: Halfplane{}}
		mut points := [max_lines]Point{init: Point{}}
		mut clean := [max_lines]Point{init: Point{}}
		mut line_count := 0
		for i in 0 .. count {
			a := values[1 + 3 * i]; b := values[2 + 3 * i]; c := values[3 + 3 * i]
			if a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128 || (a == 0 && b == 0) || gcd64(a, b) != 1 { return -1 }
			lines[line_count] = Halfplane{ a: a, b: b, c: c }; line_count++
		}
		lines[line_count] = Halfplane{ a: 1, b: 0, c: box_limit }; line_count++
		lines[line_count] = Halfplane{ a: 0, b: 1, c: box_limit }; line_count++
		lines[line_count] = Halfplane{ a: -1, b: 0, c: box_limit }; line_count++
		lines[line_count] = Halfplane{ a: 0, b: -1, c: box_limit }; line_count++
		for i in 1 .. line_count {
			key := lines[i]; mut j := i
			for j > 0 && line_compare(key, lines[j - 1]) < 0 { lines[j] = lines[j - 1]; j-- }
			lines[j] = key
		}
		mut reduced := 0
		for i in 0 .. line_count {
			if reduced > 0 && lines[i].a == lines[reduced - 1].a && lines[i].b == lines[reduced - 1].b { continue }
			lines[reduced] = lines[i]; reduced++
		}
		mut head := 0; mut tail := 0; mut empty := false
		for i in 0 .. reduced {
			h := lines[i]; mut p := Point{}
			for tail - head > 1 {
				if !intersect(queue[tail - 2], queue[tail - 1], mut p) || !outside(h, p) { break }
				tail--
			}
			for tail - head > 1 {
				if !intersect(queue[head], queue[head + 1], mut p) || !outside(h, p) { break }
				head++
			}
			if tail > head {
				last := queue[tail - 1]
				if last.a * h.b - last.b * h.a == 0 {
					if last.a * h.a + last.b * h.b < 0 { head = 0; tail = 0; empty = true; break }
					if h.c < last.c { queue[tail - 1] = h }
					continue
				}
			}
			queue[tail] = h; tail++
		}
		if empty { head = 0; tail = 0 }
		if tail - head >= 3 {
			mut p := Point{}
			for tail - head > 2 && intersect(queue[tail - 2], queue[tail - 1], mut p) && outside(queue[head], p) { tail-- }
			for tail - head > 2 && intersect(queue[head], queue[head + 1], mut p) && outside(queue[tail - 1], p) { head++ }
		}
		mut point_count := 0
		if tail - head >= 3 {
			for i in head .. tail {
				mut p := Point{}
				next := if i + 1 == tail { head } else { i + 1 }
				if !intersect(queue[i], queue[next], mut p) { point_count = 0; break }
				points[point_count] = p; point_count++
			}
		}
		mut clean_count := 0
		for i in 0 .. point_count {
			if clean_count == 0 || !same_point(clean[clean_count - 1], points[i]) { clean[clean_count] = points[i]; clean_count++ }
		}
		if clean_count > 1 && same_point(clean[0], clean[clean_count - 1]) { clean_count-- }
		mut changed := true
		for changed && clean_count >= 3 {
			changed = false
			for i in 0 .. clean_count {
				prev := (i + clean_count - 1) % clean_count; next := (i + 1) % clean_count
				if orient(clean[prev], clean[i], clean[next]) == 0 {
					for j in i .. clean_count - 1 { clean[j] = clean[j + 1] }
					clean_count--; changed = true; break
				}
			}
		}
		if clean_count < 3 { clean_count = 0 }
		if clean_count > 0 {
			mut first := 0
			for i in 1 .. clean_count { if less_yx(clean[i], clean[first]) { first = i } }
			mut rotated := [max_lines]Point{init: Point{}}
			for i in 0 .. clean_count { rotated[i] = clean[(first + i) % clean_count] }
			for i in 0 .. clean_count { clean[i] = rotated[i] }
		}
		needed := usize((1 + 4 * clean_count) * 8)
		if needed > capacity || output == nil { return -2 }
		put_i64(mut output, 0, i64(clean_count))
		for i in 0 .. clean_count {
			gx := gcd64(clean[i].x, clean[i].den); gy := gcd64(clean[i].y, clean[i].den)
			put_i64(mut output, 8 + 32 * i, clean[i].x / gx)
			put_i64(mut output, 16 + 32 * i, clean[i].den / gx)
			put_i64(mut output, 24 + 32 * i, clean[i].y / gy)
			put_i64(mut output, 32 + 32 * i, clean[i].den / gy)
		}
		return i64(needed)
	}
}
