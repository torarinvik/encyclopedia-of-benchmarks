module knights_tour_warnsdorff_open

const dx = [8]int{1,2,2,1,-1,-2,-2,-1}
const dy = [8]int{-2,-1,1,2,2,1,-1,-2}
struct TourMove { row int; col int; degree int }

fn count_neighbors(board []int, row int, col int) int {
	mut count := 0
	for i in 0 .. 8 { r,c := row+dy[i],col+dx[i]; if r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0 { count++ } }
	return count
}
fn neighbors(board []int, row int, col int) []TourMove {
	mut moves := []TourMove{cap: 8}
	for i in 0 .. 8 { r,c := row+dy[i],col+dx[i]; if r>=0&&r<8&&c>=0&&c<8&&board[r*8+c]==0 { moves << TourMove{r,c,count_neighbors(board,r,c)} } }
	for i in 1 .. moves.len { value:=moves[i];mut j:=i;for j>0&&moves[j-1].degree>value.degree {moves[j]=moves[j-1];j--};moves[j]=value }
	return moves
}
fn orphan(board []int,count int,row int,col int) bool {
	if count < 63 { for m in neighbors(board,row,col) { if count_neighbors(board,m.row,m.col)==0 { return true } } }
	return false
}
fn solve(mut board []int,row int,col int,count int) bool {
	if count>64 { return true }
	moves:=neighbors(board,row,col)
	if moves.len==0&&count!=64 { return false }
	for m in moves { board[m.row*8+m.col]=count; if !orphan(board,count,m.row,m.col)&&solve(mut board,m.row,m.col,count+1) { return true }; board[m.row*8+m.col]=0 }
	return false
}
fn put_i64(output &u8,index int,value i64) {bits:=u64(value);unsafe{for b in 0..8{output[index*8+b]=u8((bits>>u64(8*b))&255)}}}

@[export: 'knights_tour_warnsdorff_open']
pub fn knights_tour_warnsdorff_open(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if length!=0 {return -1}
	if unsafe{output==nil}||capacity<512 {return -2}
	unsafe {
		mut board:=[]int{len:64,init:0};board[0]=1
		if !solve(mut board,0,0,2) {return -1}
		mut path:=[64]i64{}
		for r in 0..8 {for c in 0..8 {path[board[r*8+c]-1]=i64(r*8+c)}}
		for i in 0..64 {put_i64(output,i,path[i])}
		return 512
	}
}
