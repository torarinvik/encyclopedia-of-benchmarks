// Independent bounded implementation of Stanford Puzzle, attributed by the
// pinned file to Forest Baskett. No upstream code/comments are copied; the
// pinned source has no explicit redistribution grant.
module stanford_puzzle

const side = 5
const cell_count = 125
const type_count = 13
const max_search_calls = 2005
const hole_scale = i64(1_000_000)
const shape_x = [13]int{4,2,1,2,4,1,3,1,1,2,2,1,2}
const shape_y = [13]int{2,1,4,4,1,2,1,3,1,2,1,2,2}
const shape_z = [13]int{1,4,2,1,2,4,1,1,3,1,2,2,2}
const shape_class = [13]int{0,0,0,0,0,0,1,1,1,2,2,2,3}

fn fits(board [cell_count]bool, start int, kind int) bool {
	x0:=start%side; y0:=(start/side)%side; z0:=start/(side*side)
	if x0+shape_x[kind]>side||y0+shape_y[kind]>side||z0+shape_z[kind]>side{return false}
	for z:=0;z<shape_z[kind];z++{for y:=0;y<shape_y[kind];y++{for x:=0;x<shape_x[kind];x++{if board[(z0+z)*side*side+(y0+y)*side+x0+x]{return false}}}}
	return true
}
fn mark(mut board [cell_count]bool,start int,kind int,value bool){
	x0:=start%side;y0:=(start/side)%side;z0:=start/(side*side)
	for z:=0;z<shape_z[kind];z++{for y:=0;y<shape_y[kind];y++{for x:=0;x<shape_x[kind];x++{board[(z0+z)*side*side+(y0+y)*side+x0+x]=value}}}
}
fn first_empty(board [cell_count]bool,start int) int {for i:=start;i<cell_count;i++{if !board[i]{return i}};return 0}
fn source_index(flat int) i64 {x:=flat%side;y:=(flat/side)%side;z:=flat/(side*side);return i64(x+1)+8*i64(y+1)+64*i64(z+1)}
fn search(mut board [cell_count]bool,mut remaining [4]int,start int,mut calls int,mut overflow bool) bool {
	calls++
	if calls>max_search_calls{overflow=true;return false}
	for kind:=0;kind<type_count;kind++{class_id:=shape_class[kind];if remaining[class_id]==0||!fits(board,start,kind){continue}
		mark(mut board,start,kind,true);remaining[class_id]--
		next:=first_empty(board,start);child:=search(mut board,mut remaining,next,mut calls,mut overflow)
		if overflow{return false};if child||next==0{return true}
		remaining[class_id]++;mark(mut board,start,kind,false)
	}
	return false
}

@[export: 'stanford_puzzle']
pub fn stanford_puzzle(input &i64,length usize) i64 {
	unsafe {
		if input==nil||length!=1||input[0]<1||input[0]>100{return -1}
		mut checksum:=i64(0);passes:=int(input[0])
		for _ in 0..passes{mut board:=[cell_count]bool{};mut remaining:=[4]int{13,3,1,1}
			if !fits(board,0,0){return -1};mark(mut board,0,0,true);remaining[0]--
			hole:=first_empty(board,0);mut calls:=0;mut overflow:=false
			if hole==0||!search(mut board,mut remaining,hole,mut calls,mut overflow)||overflow{return -1}
			checksum+=source_index(hole)*hole_scale+i64(calls)
		}
		return checksum
	}
}
