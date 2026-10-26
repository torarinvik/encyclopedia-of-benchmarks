// Clean-room TSVC s1113 profile; see package rights note.
package tsvc_s1113_feedback_anchor_add
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s1113_feedback_anchor_add :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<3||length>129 do return -1;if input[0]<1||input[0]>64 do return -1;n:=int(input[0]);if int(length)!=1+2*n do return -1;var a:[64]i64;var b:[64]i64;for i:=0;i<n;i+=1{x:=input[1+i];y:=input[1+n+i];if x< -2||x>2||y< -2||y>2 do return -1;a[i]=x;b[i]=y};if output==nil||capacity<c.size_t(8*n) do return -2;for i:=0;i<n;i+=1{a[i]=a[n/2]+b[i]};for j:=0;j<n;j+=1{put64(output,8*j,a[j])};return i64(n)}
