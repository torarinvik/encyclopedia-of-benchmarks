package mcgill_exptree

import "core:c"

MAX_LEAVES :: 4

Combination :: struct { left, right: i64, operation: int }
Search_State :: struct {
	count, depth_limit: int,
	goal, best: i64,
	stopped: bool,
	work: [8]i64,
	current, saved: [4]Combination,
}

distance_from :: proc "contextless" (a, b: i64) -> i64 {
	if a >= b do return a - b
	return b - a
}

apply :: proc "contextless" (a, b: i64, operation: int) -> i64 {
	if operation == 1 do return a + b
	if operation == 2 do return a - b
	if operation == 3 do return a * b
	return a / b
}

search :: proc "contextless" (state: ^Search_State, depth: int, used: u32) {
	if state.stopped do return
	if depth == state.depth_limit {
		candidate := state.work[state.count + depth - 1]
		if distance_from(candidate, state.goal) < distance_from(state.best, state.goal) {
			state.best = candidate
			for i := 0; i < depth; i += 1 { state.saved[i] = state.current[i] }
			if state.best == state.goal do state.stopped = true
		}
		return
	}
	for operation := 1; operation <= 4 && !state.stopped; operation += 1 {
		for first := 0; first < state.count + depth && !state.stopped; first += 1 {
			if used & (u32(1) << u32(first)) != 0 do continue
			for second := 0; second < first && !state.stopped; second += 1 {
				if used & (u32(1) << u32(second)) != 0 do continue
				left, right := state.work[first], state.work[second]
				if (operation == 3 || operation == 4) && (left == 1 || right == 1) do continue
				if left == 0 || right == 0 do continue
				if operation == 4 && left % right != 0 do continue
				if (operation == 2 || operation == 4) && left < right {
					temporary := left
					left = right
					right = temporary
				}
				state.current[depth] = Combination{left = left, right = right, operation = operation}
				state.work[state.count + depth] = apply(left, right, operation)
				search(state, depth + 1, used | (u32(1) << u32(first)) | (u32(1) << u32(second)))
			}
		}
	}
}

@(export)
mcgill_exptree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 6 do return -1
	goal, raw_count := input[0], input[1]
	if goal < 1 || goal > 1_000_000_000 || raw_count < 1 || raw_count > MAX_LEAVES do return -1
	count := int(raw_count)
	if length != c.size_t(count + 2) do return -1
	state := Search_State{count = count, goal = goal}
	for i := 0; i < count; i += 1 {
		value := input[2 + i]
		if value < 1 || value > 100 do return -1
		state.work[i] = value
	}
	for i := 0; i < count; i += 1 {
		if distance_from(state.work[i], state.goal) < distance_from(state.best, state.goal) do state.best = state.work[i]
	}
	if state.best == state.goal do return state.best
	for depth_limit := 1; depth_limit < count; depth_limit += 1 {
		state.depth_limit = depth_limit
		search(&state, 0, 0)
		if state.stopped do break
	}
	return state.best
}
