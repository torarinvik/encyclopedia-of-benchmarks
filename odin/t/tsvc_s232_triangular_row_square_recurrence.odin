// Clean-room TSVC s232 profile; see package rights note.
package tsvc_s232_triangular_row_square_recurrence
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s232_triangular_row_square_recurrence :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<9||length>51 do return -1;nr:=input[0];if nr<2||nr>5 do return -1;n:=int(nr);nn:=n*n;if int(length)!=1+2*nn do return -1;var a:[25]i64;var b:[25]i64;for i:=0;i<nn;i+=1{x:=input[1+i];y:=input[1+nn+i];if x< -1||x>1||y< -1||y>1 do return -1;a[i]=x;b[i]=y};if output==nil||capacity<c.size_t(8*nn) do return -2;for j:=1;j<n;j+=1{for i:=1;i<=j;i+=1{x:=a[j*n+i-1];a[j*n+i]=x*x+b[j*n+i]}};for i:=0;i<nn;i+=1{put64(output,8*i,a[i])};return i64(nn)}
