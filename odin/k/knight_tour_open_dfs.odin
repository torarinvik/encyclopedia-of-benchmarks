package knight_tour_open_dfs

import "core:c"

DR :: [8]int{2,1,-1,-2,-2,-1,1,2}
DC :: [8]int{1,2,2,1,-1,-2,-2,-1}

solve :: proc "contextless" (board: ^[64]int, row, col, step: int) -> bool {
	if step == 64 do return true
	for mv := 0; mv < 8; mv += 1 {
		r, c := row + DR[mv], col + DC[mv]
		if r >= 0 && r < 8 && c >= 0 && c < 8 {
			index := r*8+c
			if board[index] == -1 { board[index] = step; if solve(board,r,c,step+1) do return true; board[index] = -1 }
		}
	}
	return false
}
put_i64 :: proc "contextless" (output: [^]u8, index: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 { output[index*8+byte] = u8(bits >> (byte*8)) }
}

@(export)
knight_tour_open_dfs :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length != 0 do return -1
	if output == nil || capacity < 512 do return -2
	var board: [64]int
	for i := 0; i < 64; i += 1 { board[i] = -1 }
	board[0] = 0
	if !solve(&board,0,0,1) do return -1
	var path: [64]i64
	for r := 0; r < 8; r += 1 { for c := 0; c < 8; c += 1 { path[board[r*8+c]] = i64(r*8+c) } }
	for i: c.size_t = 0; i < 64; i += 1 { put_i64(output,i,path[i]) }
	return 512
}
