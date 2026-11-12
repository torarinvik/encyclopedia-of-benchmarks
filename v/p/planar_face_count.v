module planar_face_count

fn pfc_orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn pfc_between(a i64, b i64, p i64) bool {
	return (a <= p && p <= b) || (b <= p && p <= a)
}

fn pfc_segments_intersect(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) bool {
	o1 := pfc_orient(ax, ay, bx, by, cx, cy)
	o2 := pfc_orient(ax, ay, bx, by, dx, dy)
	o3 := pfc_orient(cx, cy, dx, dy, ax, ay)
	o4 := pfc_orient(cx, cy, dx, dy, bx, by)
	if ((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) && ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0)) {
		return true
	}
	return (o1 == 0 && pfc_between(ax, bx, cx) && pfc_between(ay, by, cy)) ||
		(o2 == 0 && pfc_between(ax, bx, dx) && pfc_between(ay, by, dy)) ||
		(o3 == 0 && pfc_between(cx, dx, ax) && pfc_between(cy, dy, ay)) ||
		(o4 == 0 && pfc_between(cx, dx, bx) && pfc_between(cy, dy, by))
}

fn pfc_half(dx i64, dy i64) int {
	return if dy > 0 || (dy == 0 && dx >= 0) { 0 } else { 1 }
}

fn pfc_angle_less(a int, b int, origin int, x &i64, y &i64) bool {
	unsafe {
		ax := x[a] - x[origin]
		ay := y[a] - y[origin]
		bx := x[b] - x[origin]
		by := y[b] - y[origin]
		ah := pfc_half(ax, ay)
		bh := pfc_half(bx, by)
		return ah < bh || (ah == bh && ax * by - ay * bx > 0)
	}
}

@[export: 'planar_face_count']
pub fn planar_face_count(input &i64, length usize) i64 {
	if length < 2 || length > 118 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 42 { return -1 }
		n := int(input[0])
		m := int(input[1])
		edge_cap := if n == 1 { 0 } else if n == 2 { 1 } else { 3 * n - 6 }
		if m > edge_cap || length != usize(2 + 2 * n + 2 * m) { return -1 }
		mut x := [16]i64{}
		mut y := [16]i64{}
		for v in 0 .. n {
			x[v] = input[2 + 2 * v]
			y[v] = input[3 + 2 * v]
			if x[v] < -100 || x[v] > 100 || y[v] < -100 || y[v] > 100 { return -1 }
			for prior in 0 .. v {
				if x[v] == x[prior] && y[v] == y[prior] { return -1 }
			}
		}
		mut adjacent := [256]bool{}
		mut neighbors := [256]int{}
		mut degree := [16]int{}
		mut edge_u := [42]int{}
		mut edge_v := [42]int{}
		offset := 2 + 2 * n
		for e in 0 .. m {
			u_value := input[offset + 2 * e]
			v_value := input[offset + 2 * e + 1]
			if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value { return -1 }
			u := int(u_value)
			v := int(v_value)
			if adjacent[u * 16 + v] { return -1 }
			adjacent[u * 16 + v] = true
			adjacent[v * 16 + u] = true
			neighbors[u * 16 + degree[u]] = v
			degree[u]++
			neighbors[v * 16 + degree[v]] = u
			degree[v]++
			edge_u[e] = u
			edge_v[e] = v
		}
		mut reached := [16]bool{}
		mut queue := [16]int{}
		mut head := 0
		mut tail := 1
		reached[0] = true
		queue[0] = 0
		for head < tail {
			u := queue[head]
			head++
			for v in 0 .. n {
				if adjacent[u * 16 + v] && !reached[v] {
					reached[v] = true
					queue[tail] = v
					tail++
				}
			}
		}
		for v in 0 .. n { if !reached[v] { return -1 } }
		for i in 0 .. m {
			for j in i + 1 .. m {
				u := edge_u[i]
				v := edge_v[i]
				a := edge_u[j]
				b := edge_v[j]
				mut common := -1
				if u == a || u == b { common = u }
				if v == a || v == b { if common < 0 { common = v } }
				if common >= 0 {
					p := if u == common { v } else { u }
					q := if a == common { b } else { a }
					ax := x[p] - x[common]
					ay := y[p] - y[common]
					bx := x[q] - x[common]
					by := y[q] - y[common]
					if ax * by == ay * bx && ax * bx + ay * by > 0 { return -1 }
				} else if pfc_segments_intersect(x[u], y[u], x[v], y[v], x[a], y[a], x[b], y[b]) {
					return -1
				}
			}
		}
		if n == 1 { return 1 }
		for u in 0 .. n {
			for i in 1 .. degree[u] {
				key := neighbors[u * 16 + i]
				mut j := i
				for j > 0 && pfc_angle_less(key, neighbors[u * 16 + j - 1], u, &x[0], &y[0]) {
					neighbors[u * 16 + j] = neighbors[u * 16 + j - 1]
					j--
				}
				neighbors[u * 16 + j] = key
			}
		}
		mut used := [256]bool{}
		mut faces := i64(0)
		for e in 0 .. m {
			for direction in 0 .. 2 {
				mut u := if direction == 0 { edge_u[e] } else { edge_v[e] }
				mut v := if direction == 0 { edge_v[e] } else { edge_u[e] }
				if used[u * 16 + v] { continue }
				faces++
				mut steps := 0
				for !used[u * 16 + v] {
					used[u * 16 + v] = true
					mut reverse := -1
					for index in 0 .. degree[v] { if neighbors[v * 16 + index] == u { reverse = index } }
					if reverse < 0 || degree[v] == 0 { return -1 }
					next := neighbors[v * 16 + (reverse + 1) % degree[v]]
					u = v
					v = next
					steps++
					if steps > 2 * m { return -1 }
				}
			}
		}
		return faces
	}
}
