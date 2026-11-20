package max_points_on_a_line

import "core:c"

MAX_N :: 16
MAX_INPUT :: 34
TABLE_SIZE :: 32

gcd_positive :: proc(a_value, b_value: int) -> int {
	a, b := a_value, b_value
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

@(export)
max_points_on_a_line :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N || length != c.size_t(1 + 2 * n_value) do return -1
	n := int(n_value)
	x: [MAX_N]int
	y: [MAX_N]int
	for i := 0; i < n; i += 1 {
		xv, yv := input[1 + 2 * i], input[2 + 2 * i]
		if xv < -100 || xv > 100 || yv < -100 || yv > 100 do return -1
		x[i], y[i] = int(xv), int(yv)
		for j := 0; j < i; j += 1 { if x[i] == x[j] && y[i] == y[j] do return -1 }
	}
	if n == 1 do return 1
	answer := i64(2)
	for anchor := 0; anchor < n; anchor += 1 {
		keys: [TABLE_SIZE]int
		counts: [TABLE_SIZE]int
		for slot := 0; slot < TABLE_SIZE; slot += 1 { keys[slot] = -1 }
		best := 0
		for other := 0; other < n; other += 1 {
			if other == anchor do continue
			dx, dy := x[other] - x[anchor], y[other] - y[anchor]
			divisor := gcd_positive(abs(dx), abs(dy))
			dx, dy = dx / divisor, dy / divisor
			if dx < 0 || (dx == 0 && dy < 0) { dx, dy = -dx, -dy }
			direction_key := dx * 401 + dy + 200
			slot := direction_key % TABLE_SIZE
			for keys[slot] != -1 && keys[slot] != direction_key { slot = (slot + 1) % TABLE_SIZE }
			if keys[slot] == -1 { keys[slot] = direction_key }
			counts[slot] += 1
			if counts[slot] > best do best = counts[slot]
		}
		if i64(best + 1) > answer do answer = i64(best + 1)
	}
	return answer
}
