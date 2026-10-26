// Clean-room TSVC s118 profile; see package rights note.
package tsvc_s118_triangular_convolution_recurrence
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s118_triangular_convolution_recurrence :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<8||length>74 do return -1;nr:=input[0];passes:=input[1];if nr<2||nr>8||passes<1||passes>4 do return -1;n:=int(nr);if int(length)!=2+n+n*n do return -1;var a:[8]i64;var b:[64]i64;for i:=0;i<n;i+=1{x:=input[2+i];if x< -1||x>1 do return -1;a[i]=x};for i:=0;i<n*n;i+=1{x:=input[2+n+i];if x< -1||x>1 do return -1;b[i]=x};if output==nil||capacity<c.size_t(8*n) do return -2;for _ in 0..<int(passes){for i:=1;i<n;i+=1{for j:=0;j<i;j+=1{a[i]+=b[j*n+i]*a[i-j-1]}}};for i:=0;i<n;i+=1{put64(output,8*i,a[i])};return i64(n)}
