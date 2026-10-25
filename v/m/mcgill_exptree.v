module mcgill_exptree

const max_leaves = 4

struct Combination {
left i64
right i64
operation int
}

struct SearchState {
mut:
	count int
	depth_limit int
	goal i64
	best i64
	stopped bool
	work [8]i64
	current [4]Combination
	saved [4]Combination
}

fn distance_from(a i64, b i64) i64 {
	if a >= b { return a - b }
	return b - a
}

fn apply(a i64, b i64, operation int) i64 {
	if operation == 1 { return a + b }
	if operation == 2 { return a - b }
	if operation == 3 { return a * b }
	return a / b
}

fn search(mut state SearchState, depth int, used u32) {
	if state.stopped { return }
	if depth == state.depth_limit {
		candidate := state.work[state.count + depth - 1]
		if distance_from(candidate, state.goal) < distance_from(state.best, state.goal) {
			state.best = candidate
			for i in 0 .. depth { state.saved[i] = state.current[i] }
			if state.best == state.goal { state.stopped = true }
		}
		return
	}
	for operation in 1 .. 5 {
		if state.stopped { break }
		for first in 0 .. state.count + depth {
			if state.stopped { break }
			if used & (u32(1) << u32(first)) != 0 { continue }
			for second in 0 .. first {
				if state.stopped { break }
				if used & (u32(1) << u32(second)) != 0 { continue }
				mut left := state.work[first]
				mut right := state.work[second]
				if (operation == 3 || operation == 4) && (left == 1 || right == 1) { continue }
				if left == 0 || right == 0 { continue }
				if operation == 4 && left % right != 0 { continue }
				if (operation == 2 || operation == 4) && left < right {
					temp := left
					left = right
					right = temp
				}
				state.current[depth] = Combination{left: left, right: right, operation: operation}
				state.work[state.count + depth] = apply(left, right, operation)
				search(mut state, depth + 1, used | (u32(1) << u32(first)) | (u32(1) << u32(second)))
			}
		}
	}
}

@[export: 'mcgill_exptree']
pub fn mcgill_exptree(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 6 { return -1 }
		goal := input[0]
		raw_count := input[1]
		if goal < 1 || goal > 1_000_000_000 || raw_count < 1 || raw_count > max_leaves { return -1 }
		count := int(raw_count)
		if length != usize(count + 2) { return -1 }
		mut state := SearchState{count: count, goal: goal}
		for i in 0 .. count {
			value := input[2 + i]
			if value < 1 || value > 100 { return -1 }
			state.work[i] = value
		}
		for i in 0 .. count {
			if distance_from(state.work[i], state.goal) < distance_from(state.best, state.goal) {
				state.best = state.work[i]
			}
		}
		if state.best == state.goal { return state.best }
		for depth_limit in 1 .. count {
			state.depth_limit = depth_limit
			search(mut state, 0, 0)
			if state.stopped { break }
		}
		return state.best
	}
}
