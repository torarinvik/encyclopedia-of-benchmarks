package sprague_grundy_theorem

import "core:c"

MAX_POSITION :: 64
MAX_MOVE_COUNT :: 32
MAX_MOVE_SIZE :: 32
MAX_INPUT_LENGTH :: 34

calculate_grundy :: proc(position: int, memo: [^]i64, values: [^]i64,
	move_count: int) -> i64 {
	if memo[position] != -1 do return memo[position]
	if position == 0 {
		memo[0] = 0
		return 0
	}

	reachable: [33]bool = {}
	for i := 0; i < move_count; i += 1 {
		move := values[2 + i]
		if move <= i64(position) {
			child := calculate_grundy(position - int(move), memo, values, move_count)
			if child >= 0 && child <= MAX_MOVE_COUNT do reachable[int(child)] = true
		}
	}
	mex := 0
	for mex <= MAX_MOVE_COUNT && reachable[mex] {
		mex += 1
	}
	memo[position] = i64(mex)
	return i64(mex)
}

// Compute a bounded single-heap subtraction game's Sprague-Grundy number.
@(export)
sprague_grundy_theorem :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	position := values[0]
	move_count_value := values[1]
	if position < 0 || position > MAX_POSITION || move_count_value < 0 || move_count_value > MAX_MOVE_COUNT do return -1
	move_count := int(move_count_value)
	if length != c.size_t(2 + move_count) do return -1
	for i := 0; i < move_count; i += 1 {
		if values[2 + i] < 1 || values[2 + i] > MAX_MOVE_SIZE do return -1
	}

	memo: [65]i64
	for i := 0; i < len(memo); i += 1 { memo[i] = -1 }
	return calculate_grundy(int(position), &memo[0], values, move_count)
}
