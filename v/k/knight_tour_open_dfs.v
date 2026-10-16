module knight_tour_open_dfs

const dr = [8]int{2, 1, -1, -2, -2, -1, 1, 2}
const dc = [8]int{1, 2, 2, 1, -1, -2, -2, -1}

fn solve(mut board []int, row int, col int, step int) bool {
	if step == 64 { return true }
	for mv in 0 .. 8 {
		r, c := row + dr[mv], col + dc[mv]
		if r >= 0 && r < 8 && c >= 0 && c < 8 {
			index := r * 8 + c
			if board[index] == -1 { board[index] = step; if solve(mut board,r,c,step+1) { return true }; board[index] = -1 }
		}
	}
	return false
}
fn put_i64(output &u8, index int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[index * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) } }
}

@[export: 'knight_tour_open_dfs']
pub fn knight_tour_open_dfs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length != 0 { return -1 }
	if unsafe { output == nil } || capacity < 512 { return -2 }
	unsafe {
		mut board := []int{len: 64, init: -1}
		board[0] = 0
		if !solve(mut board,0,0,1) { return -1 }
		mut path := [64]i64{}
		for row in 0 .. 8 { for column in 0 .. 8 { path[board[row*8+column]] = i64(row*8+column) } }
		for index in 0 .. 64 { put_i64(output,index,path[index]) }
		return 512
	}
}
