// Clean-room TSVC s1119 profile; see package rights note.
package tsvc_s1119_same_column_matrix_prefix
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s1119_same_column_matrix_prefix :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<10||length>130 do return -1;nr:=input[0];passes:=input[1];if nr<2||nr>8||passes<1||passes>4 do return -1;n:=int(nr);nn:=n*n;if int(length)!=2+2*nn do return -1;var a:[64]i64;var b:[64]i64;for i:=0;i<nn;i+=1{x:=input[2+i];y:=input[2+nn+i];if x< -1||x>1||y< -1||y>1 do return -1;a[i]=x;b[i]=y};if output==nil||capacity<c.size_t(8*nn) do return -2;for _ in 0..<int(passes){for i:=1;i<n;i+=1{for j:=0;j<n;j+=1{a[i*n+j]=a[(i-1)*n+j]+b[i*n+j]}}};for i:=0;i<nn;i+=1{put64(output,8*i,a[i])};return i64(nn)}
