package knights_tour_warnsdorff_open

import "core:c"

DX :: [8]int{1,2,2,1,-1,-2,-2,-1}
DY :: [8]int{-2,-1,1,2,2,1,-1,-2}
Move :: struct { row,col,degree:int }

count_neighbors :: proc "contextless" (board: ^[64]int, row,col:int) -> int {
	n := 0
	for i := 0; i < 8; i += 1 { r,c := row+DY[i],col+DX[i]; if r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0 { n+=1 } }
	return n
}
neighbors :: proc "contextless" (board: ^[64]int, row,col:int, moves: ^[8]Move) -> int {
	n := 0
	for i := 0; i < 8; i += 1 { r,c := row+DY[i],col+DX[i]; if r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0 { moves[n]=.{r,c,count_neighbors(board,r,c)};n+=1 } }
	for i := 1; i < n; i += 1 { value:=moves[i];j:=i;for j>0&&moves[j-1].degree>value.degree {moves[j]=moves[j-1];j-=1};moves[j]=value }
	return n
}
orphan :: proc "contextless" (board: ^[64]int,count,row,col:int) -> bool {
	if count<63 {var moves:[8]Move;n:=neighbors(board,row,col,&moves);for i:=0;i<n;i+=1 {if count_neighbors(board,moves[i].row,moves[i].col)==0 do return true}}
	return false
}
solve :: proc "contextless" (board: ^[64]int,row,col,count:int) -> bool {
	if count>64 do return true
	var moves:[8]Move;n:=neighbors(board,row,col,&moves);if n==0&&count!=64 do return false
	for i:=0;i<n;i+=1 {m:=moves[i];board[m.row*8+m.col]=count;if !orphan(board,count,m.row,m.col)&&solve(board,m.row,m.col,count+1) do return true;board[m.row*8+m.col]=0}
	return false
}
put_i64 :: proc "contextless" (output: [^]u8,index:c.size_t,value:i64) {bits:=u64(value);for b:c.size_t=0;b<8;b+=1 {output[index*8+b]=u8(bits>>(8*b))}}

@(export)
knights_tour_warnsdorff_open :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if length!=0 do return -1
	if output==nil||capacity<512 do return -2
	var board:[64]int;board[0]=1
	if !solve(&board,0,0,2) do return -1
	var path:[64]i64
	for r:=0;r<8;r+=1 {for c:=0;c<8;c+=1 {path[board[r*8+c]-1]=i64(r*8+c)}}
	for i:c.size_t=0;i<64;i+=1 {put_i64(output,i,path[i])}
	return 512
}
