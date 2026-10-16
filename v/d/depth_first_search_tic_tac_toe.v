module depth_first_search_tic_tac_toe

fn won(board &i64, player i64) bool {
	unsafe {
		for row in 0 .. 3 { if board[row * 3] == player && board[row * 3 + 1] == player && board[row * 3 + 2] == player { return true } }
		for col in 0 .. 3 { if board[col] == player && board[col + 3] == player && board[col + 6] == player { return true } }
		return (board[0] == player && board[4] == player && board[8] == player) || (board[2] == player && board[4] == player && board[6] == player)
	}
}

fn search(mut board &i64, side i64) int {
	if won(board, 1) || won(board, 2) { return -1 }
	mut available := false
	for i in 0 .. 9 { if unsafe { board[i] == 0 } { available = true } }
	if !available { return -1 }
	other := i64(3) - side
	mut best_rank := -1
	mut best_score := 0
	mut best_mask := 0
	for i in 0 .. 9 {
		if unsafe { board[i] != 0 } { continue }
		unsafe { board[i] = side }
		mut score := 0
		if won(board, 1) { score = 1 }
		else if won(board, 2) { score = 2 }
		else { child := search(mut board, other); if child >= 0 { score = child / 512 } }
		unsafe { board[i] = 0 }
		rank := if score == int(side) { 2 } else if score == 0 { 1 } else { 0 }
		if rank > best_rank { best_rank = rank; best_score = score; best_mask = 1 << i }
		else if rank == best_rank { best_mask |= 1 << i }
	}
	return best_score * 512 + best_mask
}

@[export: 'depth_first_search_tic_tac_toe']
pub fn depth_first_search_tic_tac_toe(values &i64, length usize) i64 {
	unsafe {
		if length != 10 || (values[0] != 1 && values[0] != 2) { return -1 }
		mut board := [9]i64{}
		for i in 0 .. 9 { if values[i + 1] < 0 || values[i + 1] > 2 { return -1 }; board[i] = values[i + 1] }
		result := search(mut board[0], values[0])
		return if result < 0 { 0 } else { i64(1 + result) }
	}
}
