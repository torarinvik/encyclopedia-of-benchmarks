package freebench_mason

import "core:c"

PIECE_COUNT :: 9
MAX_DEPTH :: 8
State :: [PIECE_COUNT]int
Move_Map :: [18]int

UPPER_MOVES :: [3]Move_Map{
	{0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
	{1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16},
}
LOWER_MOVES :: [3]Move_Map{
	{0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16},
	{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
	{7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5},
}
NEAR_MASK :: [18]int{0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
	0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f}

near_enough :: proc "contextless" (state: State) -> bool {
	return NEAR_MASK[state[1]]&0x02 != 0 && NEAR_MASK[state[3]]&0x08 != 0 &&
		NEAR_MASK[state[4]]&0x10 != 0 && NEAR_MASK[state[5]]&0x20 != 0 &&
		NEAR_MASK[state[0]]&0x01 != 0 && NEAR_MASK[state[2]]&0x04 != 0 &&
		NEAR_MASK[state[6]]&0x40 != 0 && NEAR_MASK[state[7]]&0x40 != 0 &&
		NEAR_MASK[state[8]]&0x40 != 0
}

is_goal :: proc "contextless" (state: State) -> bool {
	return state[0] == 5 && state[1] == 6 && state[2] == 12 && state[3] == 13 &&
		state[4] == 14 && state[5] == 15 && state[6]+state[7]+state[8] == 3
}

apply_move :: proc "contextless" (state: State, movement: int, upper: bool) -> State {
	next: State
	for piece in 0..<PIECE_COUNT {
		if upper { next[piece] = UPPER_MOVES[movement][state[piece]] }
		else { next[piece] = LOWER_MOVES[movement][state[piece]] }
	}
	return next
}

search_down :: proc "contextless" (state: State, bound, depth, last_move: int) -> bool

search_up :: proc "contextless" (state: State, bound, depth, last_move: int) -> bool {
	if depth == bound-4 && !near_enough(state) { return false }
	if is_goal(state) { return true }
	if bound <= depth { return false }
	for movement in 0..<3 {
		if movement == last_move { continue }
		next := apply_move(state, movement, true)
		if search_down(next, bound, depth+1, movement) { return true }
	}
	return false
}

search_down :: proc "contextless" (state: State, bound, depth, last_move: int) -> bool {
	if bound <= depth { return false }
	for movement in 0..<3 {
		if movement == last_move { continue }
		next := apply_move(state, movement, false)
		if search_up(next, bound, depth+1, movement) { return true }
	}
	return false
}

@(export)
freebench_mason :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != PIECE_COUNT { return -1 }
	start: State
	used: u32 = 0
	for piece in 0..<PIECE_COUNT {
		position := input[piece]
		if position < 0 || position >= 18 { return -1 }
		bit := u32(1) << u32(position)
		if used&bit != 0 { return -1 }
		used |= bit
		start[piece] = int(position)
	}
	for bound := 2; bound <= MAX_DEPTH; bound += 2 {
		if search_up(start, bound, 0, -1) { return i64(bound) }
	}
	return -2
}
