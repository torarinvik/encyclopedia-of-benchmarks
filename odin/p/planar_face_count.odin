package planar_face_count

import "core:c"

MAX_N :: 16
MAX_M :: 42
MAX_INPUT :: 118
MAX_COORD :: 100

orient :: proc(x, y: ^[MAX_N]i64, a, b, c_: int) -> i64 {
	return (x[b] - x[a]) * (y[c_] - y[a]) - (y[b] - y[a]) * (x[c_] - x[a])
}
between :: proc(a, b, p: i64) -> bool {
	return (a <= p && p <= b) || (b <= p && p <= a)
}
on_segment :: proc(x, y: ^[MAX_N]i64, a, b, p: int) -> bool {
	return between(x[a], x[b], x[p]) && between(y[a], y[b], y[p])
}
segments_intersect :: proc(x, y: ^[MAX_N]i64, a, b, c_, d: int) -> bool {
	ab_c := orient(x, y, a, b, c_)
	ab_d := orient(x, y, a, b, d)
	cd_a := orient(x, y, c_, d, a)
	cd_b := orient(x, y, c_, d, b)
	if (((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
		((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))) do return true
	return (ab_c == 0 && on_segment(x, y, a, b, c_)) || (ab_d == 0 && on_segment(x, y, a, b, d)) ||
		(cd_a == 0 && on_segment(x, y, c_, d, a)) || (cd_b == 0 && on_segment(x, y, c_, d, b))
}
angle_half :: proc(dx, dy: i64) -> int {
	if dy > 0 || (dy == 0 && dx >= 0) do return 0
	return 1
}
angle_less :: proc(a, b, origin: int, x, y: ^[MAX_N]i64) -> bool {
	ax, ay := x[a] - x[origin], y[a] - y[origin]
	bx, by := x[b] - x[origin], y[b] - y[origin]
	ah, bh := angle_half(ax, ay), angle_half(bx, by)
	return ah < bh || (ah == bh && ax * by - ay * bx > 0)
}

@(export)
planar_face_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	edge_cap := 3 * n - 6
	if n == 1 do edge_cap = 0
	if n == 2 do edge_cap = 1
	if m > edge_cap || int(length) != 2 + 2 * n + 2 * m do return -1
	x, y: [MAX_N]i64
	for v := 0; v < n; v += 1 {
		x[v], y[v] = input[2 + 2 * v], input[3 + 2 * v]
		if x[v] < -MAX_COORD || x[v] > MAX_COORD || y[v] < -MAX_COORD || y[v] > MAX_COORD do return -1
		for prior := 0; prior < v; prior += 1 {
			if x[v] == x[prior] && y[v] == y[prior] do return -1
		}
	}
	adjacent: [MAX_N * MAX_N]bool
	neighbors: [MAX_N * MAX_N]int
	degree: [MAX_N]int
	edge_u, edge_v: [MAX_M]int
	offset := 2 + 2 * n
	for e := 0; e < m; e += 1 {
		u_value, v_value := input[offset + 2 * e], input[offset + 2 * e + 1]
		if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		if adjacent[u * MAX_N + v] do return -1
		adjacent[u * MAX_N + v], adjacent[v * MAX_N + u] = true, true
		neighbors[u * MAX_N + degree[u]] = v
		degree[u] += 1
		neighbors[v * MAX_N + degree[v]] = u
		degree[v] += 1
		edge_u[e], edge_v[e] = u, v
	}
	reached: [MAX_N]bool
	queue: [MAX_N]int
	head, tail := 0, 1
	reached[0], queue[0] = true, 0
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < n; v += 1 {
			if adjacent[u * MAX_N + v] && !reached[v] {
				reached[v], queue[tail] = true, v
				tail += 1
			}
		}
	}
	for v := 0; v < n; v += 1 { if !reached[v] do return -1 }
	for i := 0; i < m; i += 1 {
		for j := i + 1; j < m; j += 1 {
			u, v, a, b := edge_u[i], edge_v[i], edge_u[j], edge_v[j]
			common := -1
			if u == a || u == b do common = u
			if v == a || v == b { if common < 0 do common = v }
			if common >= 0 {
				p := u
				if p == common do p = v
				q := a
				if q == common do q = b
				ax, ay := x[p] - x[common], y[p] - y[common]
				bx, by := x[q] - x[common], y[q] - y[common]
				if ax * by == ay * bx && ax * bx + ay * by > 0 do return -1
			} else if segments_intersect(&x, &y, u, v, a, b) do return -1
		}
	}
	if n == 1 do return 1
	for u := 0; u < n; u += 1 {
		for i := 1; i < degree[u]; i += 1 {
			key := neighbors[u * MAX_N + i]
			j := i
			for j > 0 && angle_less(key, neighbors[u * MAX_N + j - 1], u, &x, &y) {
				neighbors[u * MAX_N + j] = neighbors[u * MAX_N + j - 1]
				j -= 1
			}
			neighbors[u * MAX_N + j] = key
		}
	}
	used: [MAX_N * MAX_N]bool
	faces: i64 = 0
	for e := 0; e < m; e += 1 {
		for direction := 0; direction < 2; direction += 1 {
			u, v := edge_u[e], edge_v[e]
			if direction == 1 do u, v = v, u
			if used[u * MAX_N + v] do continue
			faces += 1
			steps := 0
			for !used[u * MAX_N + v] {
				used[u * MAX_N + v] = true
				reverse := -1
				for i := 0; i < degree[v]; i += 1 { if neighbors[v * MAX_N + i] == u do reverse = i }
				if reverse < 0 || degree[v] == 0 do return -1
				next := neighbors[v * MAX_N + (reverse + 1) % degree[v]]
				u, v = v, next
				steps += 1
				if steps > 2 * m do return -1
			}
		}
	}
	return faces
}
