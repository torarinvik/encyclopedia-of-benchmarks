package depth_first_search_tic_tac_toe

LINES :: [8][3]int{{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}}

won :: proc "contextless" (board: [^]i64, player: i64) -> bool {
	for line in LINES {
		if board[line[0]] == player && board[line[1]] == player && board[line[2]] == player do return true
	}
	return false
}

search :: proc "contextless" (board: [^]i64, side: i64) -> int {
	if won(board, 1) || won(board, 2) do return -1
	available := false
	for i := 0; i < 9; i += 1 { if board[i] == 0 do available = true }
	if !available do return -1
	other := 3 - side
	best_rank, best_score, best_mask := -1, 0, 0
	for i := 0; i < 9; i += 1 {
		if board[i] != 0 do continue
		board[i] = side
		score: int
		if won(board, 1) do score = 1
		else if won(board, 2) do score = 2
		else {
			child := search(board, other)
			score = 0
			if child >= 0 do score = child / 512
		}
		board[i] = 0
		rank := 0
		if score == int(side) { rank = 2 }
		else if score == 0 { rank = 1 }
		if rank > best_rank { best_rank = rank; best_score = score; best_mask = 1 << u32(i) }
		else if rank == best_rank do best_mask |= 1 << u32(i)
	}
	return best_score * 512 + best_mask
}

@(export, link_name="depth_first_search_tic_tac_toe")
depth_first_search_tic_tac_toe :: proc "c" (values: [^]i64, length: uint) -> i64 {
	if values == nil || length != 10 || (values[0] != 1 && values[0] != 2) do return -1
	board: [9]i64
	for i := 0; i < 9; i += 1 {
		if values[i + 1] < 0 || values[i + 1] > 2 do return -1
		board[i] = values[i + 1]
	}
	result := search(&board[0], values[0])
	if result < 0 do return 0
	return i64(1 + result)
}

main :: proc() {}
