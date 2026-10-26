// Clean-room TSVC s119 profile; see package rights note.
package tsvc_s119_diagonal_matrix_recurrence
import "core:c"
MAX_SIDE :: 8
MAX_CELLS :: 64
MAX_INPUT_LENGTH :: 130
put64 :: proc "contextless"(out:[^]u8,pos:int,v:i64){bits:=u64(v);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}
@(export)
tsvc_s119_diagonal_matrix_recurrence :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<10||length>MAX_INPUT_LENGTH do return -1
 if input[0]<2||input[0]>MAX_SIDE||input[1]<1||input[1]>4 do return -1
 n:=int(input[0]);passes:=int(input[1]);cells:=n*n;if int(length)!=2+2*cells do return -1
 var a:[MAX_CELLS]i64;var b:[MAX_CELLS]i64
 for i:=0;i<cells;i+=1{av:=input[2+i];bv:=input[2+cells+i];if av< -2||av>2||bv< -2||bv>2 do return -1;a[i]=av;b[i]=bv}
 bytes:=8*cells;if output==nil||capacity<c.size_t(bytes) do return -2
 for p:=0;p<passes;p+=1{for i:=1;i<n;i+=1{for j:=1;j<n;j+=1{a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j]}}}
 for i:=0;i<cells;i+=1{put64(output,8*i,a[i])};return i64(cells)
}
