// Clean-room implementation of TSVC vtv; see package rights note.
package tsvc_vtv_elementwise_product
import "core:c"
MAX_N :: 32
MAX_INPUT_LENGTH :: 66
store_i64_le :: proc "contextless"(out:[^]u8,pos:int,value:i64){bits:=u64(value);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}
@(export)
tsvc_vtv_elementwise_product :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||length>MAX_INPUT_LENGTH do return -1
 if input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>8||length!=c.size_t(2+2*input[0]) do return -1
 n:=int(input[0]);passes:=int(input[1]);var a:[MAX_N]f64;var b:[MAX_N]f64
 for i:=0;i<n;i+=1{av:=input[2+i];bv:=input[2+n+i];if av< -2||av>2||bv< -2||bv>2 do return -1;a[i]=f64(av);b[i]=f64(bv)}
 bytes:=8*n;if output==nil||capacity<c.size_t(bytes) do return -2
 for p:=0;p<passes;p+=1{for i:=0;i<n;i+=1{a[i]*=b[i]}}
 for i:=0;i<n;i+=1{store_i64_le(output,8*i,i64(a[i]))};return i64(bytes)
}
