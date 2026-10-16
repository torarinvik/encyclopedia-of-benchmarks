package minesweeper

import "core:c"

MAX_DIM :: 32
MAX_CELLS :: 1024
MAX_OUTPUT :: 8200
write_i64 :: proc "contextless" (out: [^]u8, pos_value: int, value: i64) -> int {
	pos:=pos_value;bits:=u64(value)
	for i:=0;i<8;i+=1{out[pos]=u8((bits>>(8*i))&255);pos+=1}
	return pos
}
@(export)
minesweeper :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<2||length>2+MAX_CELLS do return -1
	rv,cv:=input[0],input[1];if rv<1||rv>MAX_DIM||cv<1||cv>MAX_DIM do return -1
	rows,cols:=int(rv),int(cv);count:=rows*cols;if length!=c.size_t(2+count) do return -1
	cells:[MAX_CELLS]u8;for i:=0;i<count;i+=1{v:=input[2+i];if v!=0&&v!=1 do return -1;cells[i]=u8(v)}
	neighbors:[MAX_CELLS]i64
	for row:=0;row<rows;row+=1{for col:=0;col<cols;col+=1{mines:=i64(0);for dr:=-1;dr<=1;dr+=1{for dc:=-1;dc<=1;dc+=1{if dr==0&&dc==0 do continue;nr,nc:=row+dr,col+dc;if nr>=0&&nr<rows&&nc>=0&&nc<cols&&cells[nr*cols+nc]==1{mines+=1}}};neighbors[row*cols+col]=mines}}
	needed:=8+8*count;if output==nil||capacity<c.size_t(needed) do return -2
	pos:=write_i64(output,0,i64(count));for i:=0;i<count;i+=1{pos=write_i64(output,pos,neighbors[i])};return i64(pos)
}
