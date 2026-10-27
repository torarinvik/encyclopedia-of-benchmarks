package geometric_greedy_compass_routing

import "core:c"

MAX_N :: 8
MAX_INPUT :: 84
MAX_OUTPUT :: 80
OUTPUT_VALUES :: 10

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}
angle_better :: proc(da, la, db, lb: i64) -> bool {
	if (da >= 0) != (db >= 0) do return da >= 0
	left, right := da*da*lb, db*db*la
	if da >= 0 do return left > right
	return left < right
}
angle_equal :: proc(da, la, db, lb: i64) -> bool {
	return (da >= 0) == (db >= 0) && da*da*lb == db*db*la
}

@(export)
geometric_greedy_compass_routing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 12 || length > MAX_INPUT do return -1
	n64, mode, source64, target64 := input[0], input[1], input[2], input[3]
	if n64 < 2 || n64 > MAX_N || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64 do return -1
	n, source, target := int(n64), int(source64), int(target64)
	if length != c.size_t(4+2*n+n*n) do return -1
	x: [MAX_N]i64
	y: [MAX_N]i64
	adjacency := 4+2*n
	for i := 0; i < n; i += 1 {
		x[i], y[i] = input[4+i], input[4+n+i]
		if x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8 do return -1
		for j := 0; j < i; j += 1 { if x[i] == x[j] && y[i] == y[j] do return -1 }
	}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			a, b := input[adjacency+i*n+j], input[adjacency+j*n+i]
			if (a != 0 && a != 1) || a != b || (i == j && a != 0) do return -1
		}
	}
	if output == nil || capacity < c.size_t(MAX_OUTPUT) do return -2
	path: [MAX_N]int
	visited: [MAX_N]bool
	count := 1
	path[0] = source
	visited[source] = true
	current := source
	for current != target && count < n {
		best := n
		best_dot: i64 = 0
		best_len: i64 = 1
		best_distance: i64 = 0
		tx, ty := x[target]-x[current], y[target]-y[current]
		for v := 0; v < n; v += 1 {
			if input[adjacency+current*n+v] != 1 do continue
			better := best == n
			dx, dy := x[v]-x[current], y[v]-y[current]
			if mode == 0 {
				rx, ry := x[v]-x[target], y[v]-y[target]
				distance := rx*rx+ry*ry
				if !better do better = distance < best_distance || (distance == best_distance && v < best)
				if better do best_distance = distance
			} else {
				dot, len := dx*tx+dy*ty, dx*dx+dy*dy
				if !better do better = angle_better(dot,len,best_dot,best_len) || (angle_equal(dot,len,best_dot,best_len) && v < best)
				if better { best_dot, best_len = dot, len }
			}
			if better do best = v
		}
		if best == n || visited[best] do break
		path[count] = best
		count += 1
		visited[best] = true
		current = best
	}
	record: [OUTPUT_VALUES]i64
	if current == target do record[0] = 1 else do record[0] = 0
	record[1] = i64(count-1)
	for i := 0; i < MAX_N; i += 1 { record[2+i] = -1 }
	for i := 0; i < count; i += 1 { record[2+i] = i64(path[i]) }
	staged: [MAX_OUTPUT]u8
	for i := 0; i < OUTPUT_VALUES; i += 1 { put64(&staged[0],8*i,record[i]) }
	for i := 0; i < MAX_OUTPUT; i += 1 { output[i] = staged[i] }
	return i64(MAX_OUTPUT)
}
