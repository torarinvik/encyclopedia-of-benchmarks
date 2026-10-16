const max_size = 16
fn fill(mut board []i32, width int, row int, col int, mr int, mc int, mut tile int) {
	if width == 1 { return }
	h := width / 2; t := tile; tile++
	qr := [row, row, row+h, row+h]; qc := [col, col+h, col, col+h]
	cr := [row+h-1, row+h-1, row+h, row+h]; cc := [col+h-1, col+h, col+h-1, col+h]
	missing := if mr < row+h { if mc < col+h { 0 } else { 1 } } else { if mc < col+h { 2 } else { 3 } }
	for q in 0 .. 4 {
		nr := if q == missing { mr } else { cr[q] }; nc := if q == missing { mc } else { cc[q] }
		if q != missing { board[cr[q]*max_size+cc[q]] = t }
		fill(mut board, h, qr[q], qc[q], nr, nc, mut tile)
	}
}
@[export: 'tiling_problem']
pub fn tiling_problem(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != 3 { return -1 }
	s := unsafe { values[0] }
	if s < 1 || s > max_size || (s & (s-1)) != 0 || unsafe { values[1] < 0 || values[1] >= s || values[2] < 0 || values[2] >= s } { return -1 }
	size := int(s); mut board := [max_size*max_size]i32{}; mut tile := 1
	fill(mut board[..], size, 0, 0, int(unsafe { values[1] }), int(unsafe { values[2] }), mut tile)
	bytes := size*size*4
	if unsafe { output == nil } || output_capacity < usize(bytes) { return -2 }
	for i in 0 .. size*size {
		x := u32(board[(i/size)*max_size+i%size])
		for b in 0 .. 4 { unsafe { output[i*4+b] = u8((x >> (8*b)) & 255) } }
	}
	return i64(bytes)
}
