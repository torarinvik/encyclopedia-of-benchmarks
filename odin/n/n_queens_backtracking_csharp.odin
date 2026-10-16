package n_queens_backtracking_csharp

import "core:c"

MAX_N :: 8
MAX_OUTPUT_WORDS :: 737

safe :: proc "contextless" (rows: ^[MAX_N]int, column,row:int) -> bool {
	for c := 0; c < column; c += 1 { prior:=rows[c]; if prior==row || prior-c==row-column || prior+c==row+column do return false }
	return true
}
enumerate :: proc "contextless" (n,column:int,rows: ^[MAX_N]int,values: ^[MAX_OUTPUT_WORDS]i64,used: ^int) {
	if column==n {for c:=0;c<n;c+=1 {values[used^]=i64(rows[c]);used^+=1};values[0]+=1;return}
	for row:=0;row<n;row+=1 {if safe(rows,column,row) {rows[column]=row;enumerate(n,column+1,rows,values,used)}}
}
put_i64 :: proc "contextless" (output:[^]u8,index:c.size_t,value:i64) {bits:=u64(value);for b:c.size_t=0;b<8;b+=1 {output[index*8+b]=u8(bits>>(8*b))}}

@(export)
n_queens_backtracking_csharp :: proc "c" (n:i64,output:[^]u8,capacity:c.size_t)->i64 {
	if n<0||n>MAX_N do return -1
	var values:[MAX_OUTPUT_WORDS]i64;var used:=1
	if n>0 {var rows:[MAX_N]int;enumerate(int(n),0,&rows,&values,&used)}
	required:=c.size_t(used*8);if output==nil||capacity<required do return -2
	for i:c.size_t=0;i<c.size_t(used);i+=1 {put_i64(output,i,values[i])}
	return i64(required)
}
