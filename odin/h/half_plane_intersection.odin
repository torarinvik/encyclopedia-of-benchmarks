package half_plane_intersection

import "core:c"

MAX_LINES :: 16
MAX_INPUT :: 37
BOX_LIMIT :: i64(256)

Halfplane :: struct { a, b, c: i64 }
Point :: struct { x, y, den: i64 }

abs64 :: proc(x: i64) -> i64 { if x < 0 do return -x; return x }
gcd64 :: proc(a0, b0: i64) -> i64 {
	a, b := abs64(a0), abs64(b0)
	for b != 0 { r := a % b; a = b; b = r }
	return a
}
angle_half :: proc(h: Halfplane) -> int { if h.b > 0 || (h.b == 0 && h.a >= 0) do return 0; return 1 }
line_compare :: proc(x, y: Halfplane) -> int {
	hx, hy := angle_half(x), angle_half(y)
	if hx != hy do return if hx < hy then -1 else 1
	turn := x.a * y.b - x.b * y.a
	if turn != 0 do return if turn > 0 then -1 else 1
	if x.c < y.c do return -1
	if x.c > y.c do return 1
	return 0
}
intersect :: proc(x, y: Halfplane, p: ^Point) -> bool {
	det := x.a * y.b - y.a * x.b
	if det == 0 do return false
	xn, yn := x.c * y.b - x.b * y.c, x.a * y.c - x.c * y.a
	if det < 0 { det = -det; xn = -xn; yn = -yn }
	g := gcd64(gcd64(xn, yn), det)
	p^ = Point{xn / g, yn / g, det / g}
	return true
}
outside :: proc(h: Halfplane, p: Point) -> bool { return h.a * p.x + h.b * p.y > h.c * p.den }
same_point :: proc(x, y: Point) -> bool { return x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den }
orient :: proc(a, b, c: Point) -> i64 {
	dx1, dy1 := b.x * a.den - a.x * b.den, b.y * a.den - a.y * b.den
	dx2, dy2 := c.x * b.den - b.x * c.den, c.y * b.den - b.y * c.den
	return dx1 * dy2 - dy1 * dx2
}
less_yx :: proc(a, b: Point) -> bool {
	y1, y2 := a.y * b.den, b.y * a.den
	if y1 != y2 do return y1 < y2
	return a.x * b.den < b.x * a.den
}
put_i64 :: proc(out: [^]u8, offset: ^int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset^] = u8((bits >> u64(8*b)) & 255); offset^ += 1 }
}

@(export)
half_plane_intersection :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > c.size_t(MAX_INPUT) || v[0] < 0 || v[0] > 12 do return -1
	count := int(v[0])
	if n != c.size_t(1 + 3*count) do return -1
	var lines, queue: [MAX_LINES]Halfplane
	var points, clean: [MAX_LINES]Point
	line_count := 0
	for i := 0; i < count; i += 1 {
		a, b, c0 := v[1+3*i], v[2+3*i], v[3+3*i]
		if a < -16 || a > 16 || b < -16 || b > 16 || c0 < -128 || c0 > 128 || (a == 0 && b == 0) || gcd64(a, b) != 1 do return -1
		lines[line_count] = Halfplane{a, b, c0}; line_count += 1
	}
	lines[line_count] = Halfplane{1, 0, BOX_LIMIT}; line_count += 1
	lines[line_count] = Halfplane{0, 1, BOX_LIMIT}; line_count += 1
	lines[line_count] = Halfplane{-1, 0, BOX_LIMIT}; line_count += 1
	lines[line_count] = Halfplane{0, -1, BOX_LIMIT}; line_count += 1
	for i := 1; i < line_count; i += 1 {
		key := lines[i]; j := i
		for j > 0 && line_compare(key, lines[j-1]) < 0 { lines[j] = lines[j-1]; j -= 1 }
		lines[j] = key
	}
	reduced := 0
	for i := 0; i < line_count; i += 1 {
		if reduced > 0 && lines[i].a == lines[reduced-1].a && lines[i].b == lines[reduced-1].b do continue
		lines[reduced] = lines[i]; reduced += 1
	}
	head, tail, empty := 0, 0, false
	for i := 0; i < reduced; i += 1 {
		h := lines[i]; p: Point
		for tail-head > 1 {
			if !intersect(queue[tail-2], queue[tail-1], &p) || !outside(h, p) do break
			tail -= 1
		}
		for tail-head > 1 {
			if !intersect(queue[head], queue[head+1], &p) || !outside(h, p) do break
			head += 1
		}
		if tail > head {
			last := queue[tail-1]
			if last.a*h.b-last.b*h.a == 0 {
				if last.a*h.a+last.b*h.b < 0 { head = 0; tail = 0; empty = true; break }
				if h.c < last.c do queue[tail-1] = h
				continue
			}
		}
		queue[tail] = h; tail += 1
	}
	if empty { head = 0; tail = 0 }
	if tail-head >= 3 {
		p: Point
		for tail-head > 2 && intersect(queue[tail-2], queue[tail-1], &p) && outside(queue[head], p) do tail -= 1
		for tail-head > 2 && intersect(queue[head], queue[head+1], &p) && outside(queue[tail-1], p) do head += 1
	}
	point_count := 0
	if tail-head >= 3 {
		for i := head; i < tail; i += 1 {
			p: Point; next := i+1
			if next == tail do next = head
			if !intersect(queue[i], queue[next], &p) { point_count = 0; break }
			points[point_count] = p; point_count += 1
		}
	}
	clean_count := 0
	for i := 0; i < point_count; i += 1 {
		if clean_count == 0 || !same_point(clean[clean_count-1], points[i]) { clean[clean_count] = points[i]; clean_count += 1 }
	}
	if clean_count > 1 && same_point(clean[0], clean[clean_count-1]) do clean_count -= 1
	changed := true
	for changed && clean_count >= 3 {
		changed = false
		for i := 0; i < clean_count; i += 1 {
			prev, next := (i+clean_count-1)%clean_count, (i+1)%clean_count
			if orient(clean[prev], clean[i], clean[next]) == 0 {
				for j := i; j+1 < clean_count; j += 1 { clean[j] = clean[j+1] }
				clean_count -= 1; changed = true; break
			}
		}
	}
	if clean_count < 3 do clean_count = 0
	if clean_count > 0 {
		first := 0
		for i := 1; i < clean_count; i += 1 { if less_yx(clean[i], clean[first]) do first = i }
		var rotated: [MAX_LINES]Point
		for i := 0; i < clean_count; i += 1 { rotated[i] = clean[(first+i)%clean_count] }
		for i := 0; i < clean_count; i += 1 { clean[i] = rotated[i] }
	}
	needed := (1+4*clean_count)*8
	if c.size_t(needed) > cap || out == nil do return -2
	offset := 0; put_i64(out, &offset, i64(clean_count))
	for i := 0; i < clean_count; i += 1 {
		gx, gy := gcd64(clean[i].x, clean[i].den), gcd64(clean[i].y, clean[i].den)
		put_i64(out, &offset, clean[i].x/gx); put_i64(out, &offset, clean[i].den/gx)
		put_i64(out, &offset, clean[i].y/gy); put_i64(out, &offset, clean[i].den/gy)
	}
	return i64(needed)
}
