package infinite_knight_distance

import "core:c"

MAX_COORDINATE :: i64(1_000_000_000)

@(export, link_name="infinite_knight_distance")
infinite_knight_distance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	dx, dy := input[0], input[1]
	if dx < -MAX_COORDINATE || dx > MAX_COORDINATE || dy < -MAX_COORDINATE || dy > MAX_COORDINATE do return -1
	abs_x := dx
	abs_y := dy
	if dx < 0 do abs_x = -dx
	if dy < 0 do abs_y = -dy
	large := max(abs_x, abs_y)
	small := min(abs_x, abs_y)
	if large == 1 && small == 0 do return 3
	if large == 2 && small == 2 do return 4
	distance := (large + 1) / 2
	diagonal_bound := (large + small + 2) / 3
	if diagonal_bound > distance do distance = diagonal_bound
	if (large + small - distance) % 2 != 0 do distance += 1
	return distance
}
