module main

const max_depth = 8
const upper_moves = [3][18]int{
	[18]int{0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6},
	[18]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
	[18]int{1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16},
}
const lower_moves = [3][18]int{
	[18]int{0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16},
	[18]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
	[18]int{7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5},
}
const near_mask = [18]int{0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
	0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f}

fn near_enough(state [9]int) bool {
	return near_mask[state[1]] & 0x02 != 0 && near_mask[state[3]] & 0x08 != 0 &&
		near_mask[state[4]] & 0x10 != 0 && near_mask[state[5]] & 0x20 != 0 &&
		near_mask[state[0]] & 0x01 != 0 && near_mask[state[2]] & 0x04 != 0 &&
		near_mask[state[6]] & 0x40 != 0 && near_mask[state[7]] & 0x40 != 0 &&
		near_mask[state[8]] & 0x40 != 0
}

fn is_goal(state [9]int) bool {
	return state[0] == 5 && state[1] == 6 && state[2] == 12 && state[3] == 13 &&
		state[4] == 14 && state[5] == 15 && state[6] + state[7] + state[8] == 3
}

fn apply_move(state [9]int, movement int, upper bool) [9]int {
	mut next := [9]int{}
	for piece in 0 .. 9 {
		next[piece] = if upper { upper_moves[movement][state[piece]] } else { lower_moves[movement][state[piece]] }
	}
	return next
}

fn search_down(state [9]int, bound int, depth int, last_move int) bool

fn search_up(state [9]int, bound int, depth int, last_move int) bool {
	if depth == bound - 4 && !near_enough(state) { return false }
	if is_goal(state) { return true }
	if bound <= depth { return false }
	for movement in 0 .. 3 {
		if movement == last_move { continue }
		next := apply_move(state, movement, true)
		if search_down(next, bound, depth + 1, movement) { return true }
	}
	return false
}

fn search_down(state [9]int, bound int, depth int, last_move int) bool {
	if bound <= depth { return false }
	for movement in 0 .. 3 {
		if movement == last_move { continue }
		next := apply_move(state, movement, false)
		if search_up(next, bound, depth + 1, movement) { return true }
	}
	return false
}

@[export: 'freebench_mason']
pub fn freebench_mason(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != usize(9) { return -1 }
	mut start := [9]int{}
	mut used := u32(0)
	for piece in 0 .. 9 {
		position := unsafe { input[piece] }
		if position < 0 || position >= 18 { return -1 }
		bit := u32(1) << u32(position)
		if used & bit != 0 { return -1 }
		used |= bit
		start[piece] = int(position)
	}
	for bound := 2; bound <= max_depth; bound += 2 {
		if search_up(start, bound, 0, -1) { return i64(bound) }
	}
	return -2
}
