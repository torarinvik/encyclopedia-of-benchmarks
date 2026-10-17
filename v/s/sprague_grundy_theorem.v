module sprague_grundy_theorem

fn calculate_grundy(position int, mut memo []i64, moves []i64) i64 {
	if memo[position] != -1 { return memo[position] }
	if position == 0 {
		memo[0] = 0
		return 0
	}
	mut reachable := []bool{len: 33, init: false}
	for move_size in moves {
		move := int(move_size)
		if move <= position {
			child := calculate_grundy(position - move, mut memo, moves)
			reachable[int(child)] = true
		}
	}
	mut mex := 0
	for mex <= 32 && reachable[mex] { mex++ }
	memo[position] = i64(mex)
	return i64(mex)
}

// Compute a bounded single-heap subtraction game's Sprague-Grundy number.
@[export: 'sprague_grundy_theorem']
pub fn sprague_grundy_theorem(values &i64, length usize) i64 {
	if length < 2 || unsafe { values == nil } { return -1 }
	unsafe {
		if length > 34 { return -1 }
		position_value := values[0]
		move_count_value := values[1]
		if position_value < 0 || position_value > 64 || move_count_value < 0 || move_count_value > 32 { return -1 }
		move_count := int(move_count_value)
		if int(length) != 2 + move_count { return -1 }
		mut moves := []i64{len: move_count}
		for i in 0 .. move_count {
			move := values[2 + i]
			if move < 1 || move > 32 { return -1 }
			moves[i] = move
		}
		mut memo := []i64{len: int(position_value) + 1, init: -1}
		return calculate_grundy(int(position_value), mut memo, moves)
	}
}
