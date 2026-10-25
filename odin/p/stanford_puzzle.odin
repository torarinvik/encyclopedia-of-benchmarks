// Independent bounded implementation of Stanford Puzzle, attributed by the
// pinned file to Forest Baskett. No upstream code/comments are copied; the
// pinned source has no explicit redistribution grant.
package stanford_puzzle
import "core:c"

side :: 5
cell_count :: 125
type_count :: 13
max_search_calls :: 2005
hole_scale :: i64(1_000_000)
shape_x :: [13]int{4,2,1,2,4,1,3,1,1,2,2,1,2}
shape_y :: [13]int{2,1,4,4,1,2,1,3,1,2,1,2,2}
shape_z :: [13]int{1,4,2,1,2,4,1,1,3,1,2,2,2}
shape_class :: [13]int{0,0,0,0,0,0,1,1,1,2,2,2,3}

fits :: proc(board: ^[cell_count]bool,start,kind:int)->bool{
    x0:=start%side;y0:=(start/side)%side;z0:=start/(side*side)
    if x0+shape_x[kind]>side||y0+shape_y[kind]>side||z0+shape_z[kind]>side{return false}
    for z in 0..<shape_z[kind]{for y in 0..<shape_y[kind]{for x in 0..<shape_x[kind]{if board[(z0+z)*side*side+(y0+y)*side+x0+x]{return false}}}}
    return true
}
mark :: proc(board: ^[cell_count]bool,start,kind:int,value:bool){
    x0:=start%side;y0:=(start/side)%side;z0:=start/(side*side)
    for z in 0..<shape_z[kind]{for y in 0..<shape_y[kind]{for x in 0..<shape_x[kind]{board[(z0+z)*side*side+(y0+y)*side+x0+x]=value}}}
}
first_empty :: proc(board: ^[cell_count]bool,start:int)->int{for i in start..<cell_count{if !board[i]{return i}};return 0}
source_index :: proc(flat:int)->i64{x:=flat%side;y:=(flat/side)%side;z:=flat/(side*side);return i64(x+1)+8*i64(y+1)+64*i64(z+1)}
search :: proc(board: ^[cell_count]bool,remaining: ^[4]int,start:int,calls:^int,overflow:^bool)->bool{
    calls^+=1;if calls^>max_search_calls{overflow^=true;return false}
    for kind in 0..<type_count{class_id:=shape_class[kind];if remaining[class_id]==0||!fits(board,start,kind){continue}
        mark(board,start,kind,true);remaining[class_id]-=1;next:=first_empty(board,start);child:=search(board,remaining,next,calls,overflow)
        if overflow^ {return false};if child||next==0{return true};remaining[class_id]+=1;mark(board,start,kind,false)
    }
    return false
}

@(export)
stanford_puzzle :: proc "c" (input:[^]i64,length:c.size_t)->i64{
    if input==nil||length!=1||input[0]<1||input[0]>100 do return -1
    checksum:=i64(0)
    for _ in 0..<int(input[0]){
        board:=[cell_count]bool{};remaining:=[4]int{13,3,1,1};if !fits(&board,0,0) do return -1
        mark(&board,0,0,true);remaining[0]-=1;hole:=first_empty(&board,0);calls:=0;overflow:=false
        if hole==0||!search(&board,&remaining,hole,&calls,&overflow)||overflow do return -1
        checksum+=source_index(hole)*hole_scale+i64(calls)
    }
    return checksum
}
