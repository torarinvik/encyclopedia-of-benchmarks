// Clean-room TSVC s1111 profile; see package rights note.
package tsvc_s1111_stride_two_polynomial_map
import "core:c"
MAX_N :: 32
put64 :: proc "contextless"(out:[^]u8,pos:int,v:i64){bits:=u64(v);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}
@(export)
tsvc_s1111_stride_two_polynomial_map :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<6||length>161 do return -1
 nr:=input[0];if nr<1||nr>MAX_N do return -1;n:=int(nr);if int(length)!=1+5*n do return -1
 var a:[64]i64;var b:[32]i64;var cc:[32]i64;var d:[32]i64;off:=1
 for i:=0;i<2*n;i+=1{x:=input[off+i];if x< -2||x>2 do return -1;a[i]=x};off+=2*n
 for i:=0;i<n;i+=1{x:=input[off+i];if x< -2||x>2 do return -1;b[i]=x};off+=n
 for i:=0;i<n;i+=1{x:=input[off+i];if x< -2||x>2 do return -1;cc[i]=x};off+=n
 for i:=0;i<n;i+=1{x:=input[off+i];if x< -2||x>2 do return -1;d[i]=x}
 bytes:=16*n;if output==nil||capacity<c.size_t(bytes) do return -2
 for i:=0;i<n;i+=1{a[2*i]=cc[i]*b[i]+d[i]*b[i]+cc[i]*cc[i]+d[i]*b[i]+d[i]*cc[i]}
 for i:=0;i<2*n;i+=1{put64(output,8*i,a[i])};return i64(2*n)
}
