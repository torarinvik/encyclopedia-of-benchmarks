package tiling_problem
import "core:c"
max_size :: 16
fill :: proc(board: ^[256]int, width, row, col, mr, mc: int, tile: ^int) {
	if width == 1 { return }
	h := width/2; t := tile^; tile^ += 1
	qr := [4]int{row,row,row+h,row+h}; qc := [4]int{col,col+h,col,col+h}
	cr := [4]int{row+h-1,row+h-1,row+h,row+h}; cc := [4]int{col+h-1,col+h,col+h-1,col+h}
	missing := 3
	if mr < row+h { missing = 1; if mc < col+h do missing = 0 } else if mc < col+h { missing = 2 }
	for q in 0..<4 { nr,nc := mr,mc; if q != missing { board[cr[q]*max_size+cc[q]]=t;nr,nc=cr[q],cc[q] };fill(board,h,qr[q],qc[q],nr,nc,tile) }
}
@(export)
tiling_problem :: proc "c" (v: [^]i64,n: c.size_t,out: [^]u8,cap: c.size_t)->i64 {
	if v==nil||n!=3 do return -1
	s:=v[0];if s<1||s>max_size||(s&(s-1))!=0||v[1]<0||v[1]>=s||v[2]<0||v[2]>=s do return -1
	size:=int(s);board:=[256]int{};tile:=1;fill(&board,size,0,0,int(v[1]),int(v[2]),&tile)
	bytes:=size*size*4;if out==nil||cap<c.size_t(bytes) do return -2
	for i in 0..<size*size {x:=u32(board[(i/size)*max_size+i%size]);for b in 0..<4 do out[i*4+b]=u8(x>>(8*b))};return i64(bytes)
}
