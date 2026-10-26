// Clean-room TSVC s471 profile; see package rights note.
package tsvc_s471_ordered_two_vector_map
import "core:c"
MAX_N :: 32
MAX_INPUT_LENGTH :: 130
put64 :: proc "contextless"(out:[^]u8,pos:int,value:i64){bits:=u64(value);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}
@(export)
tsvc_s471_ordered_two_vector_map :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<6||length>MAX_INPUT_LENGTH do return -1
 if input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>4||length!=c.size_t(2+4*input[0]) do return -1
 n:=int(input[0]);passes:=int(input[1]);var x:[MAX_N]f64;var b:[MAX_N]f64;var cc:[MAX_N]f64;var d:[MAX_N]f64;var e:[MAX_N]f64
 for i:=0;i<n;i+=1{bv:=input[2+i];cv:=input[2+n+i];dv:=input[2+2*n+i];ev:=input[2+3*n+i];if bv< -2||bv>2||cv< -2||cv>2||dv< -2||dv>2||ev< -2||ev>2 do return -1;b[i]=f64(bv);cc[i]=f64(cv);d[i]=f64(dv);e[i]=f64(ev)}
 bytes:=16*n;if output==nil||capacity<c.size_t(bytes) do return -2
 for p:=0;p<passes;p+=1{for i:=0;i<n;i+=1{x[i]=b[i]+d[i]*d[i];b[i]=cc[i]+d[i]*e[i]}}
 for i:=0;i<n;i+=1{put64(output,8*i,i64(x[i]));put64(output,8*(n+i),i64(b[i]))};return i64(bytes)
}
