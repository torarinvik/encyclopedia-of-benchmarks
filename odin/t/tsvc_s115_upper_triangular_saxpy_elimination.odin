// Clean-room TSVC s115 profile; see package rights note.
package tsvc_s115_upper_triangular_saxpy_elimination
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for k:=0;k<8;k+=1{o[p+k]=u8(b&255);b>>=8}}
@(export)
tsvc_s115_upper_triangular_saxpy_elimination :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<8||length>58 do return -1;if input[0]<2||input[0]>7||input[1]<1||input[1]>3 do return -1;n:=int(input[0]);passes:=int(input[1]);if int(length)!=2+n+n*n do return -1;var a:[8]i64;var m:[64]i64;for i:=0;i<n;i+=1{x:=input[2+i];if x< -1||x>1 do return -1;a[i]=x};for i:=0;i<n*n;i+=1{x:=input[2+n+i];if x< -1||x>1 do return -1;m[i]=x};if output==nil||capacity<c.size_t(8*n) do return -2;for p:=0;p<passes;p+=1{for j:=0;j<n;j+=1{for i:=j+1;i<n;i+=1{a[i]-=m[j*n+i]*a[j]}}};for i:=0;i<n;i+=1{put64(output,8*i,a[i])};return i64(n)}
