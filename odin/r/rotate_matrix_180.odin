package rotate_matrix_180
import "core:c"
const MAX_CELLS=1024
store_le :: proc(out:[^]u8,off:int,value:i64){bits:=u64(value);for b in 0..<8{out[off+b]=u8((bits>>(b*8))&255)}}
@(export)
rotate_matrix_180 :: proc "c" (v:[^]i64,n:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if v==nil||n<2||n>1027 do return -1;r,c:=v[0],v[1];if r<1||r>32||c<1||c>32||n!=2+c.size_t(r*c) do return -1;rows,cols:=int(r),int(c);matrix:[MAX_CELLS]i64={};result:[MAX_CELLS]i64={};for i in 0..<rows*cols{matrix[i]=v[2+i]};out_rows,out_cols:=int(rows),int(cols);for i in 0..<rows{for j in 0..<cols{rr,cc:=int(rows-1-i),int(cols-1-j);result[rr*out_cols+cc]=matrix[i*cols+j]}};bytes:=8*(2+out_rows*out_cols);if output==nil||capacity<c.size_t(bytes) do return -2;store_le(output,0,i64(out_rows));store_le(output,8,i64(out_cols));for i in 0..<out_rows*out_cols{store_le(output,16+8*i,result[i])};return i64(bytes)}
