package smith_weighted_completion_time
import "core:c"
MAX_N::12;MAX_INPUT::25
put64::proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
smith_weighted_completion_time::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1
 n64:=input[0];if n64<1||n64>MAX_N||length!=c.size_t(1+2*n64) do return -1
 n:=int(n64);p:[MAX_N]i64;w:[MAX_N]i64;order:[MAX_N]i64
 for i:=0;i<n;i+=1{p[i]=input[1+2*i];w[i]=input[2+2*i];if p[i]<1||p[i]>10000||w[i]<1||w[i]>10000 do return -1;order[i]=i64(i)}
 bytes:=8*(n+1);if output==nil||capacity<c.size_t(bytes) do return -2
 for i:=1;i<n;i+=1{key:=order[i];j:=i;for j>0{prev:=int(order[j-1]);k:=int(key);before:=w[k]*p[prev]>w[prev]*p[k]||(w[k]*p[prev]==w[prev]*p[k]&&k<prev);if !before do break;order[j]=order[j-1];j-=1};order[j]=key}
 elapsed,total:i64=0,0
 for i:=0;i<n;i+=1{job:=int(order[i]);elapsed+=p[job];total+=w[job]*elapsed}
 put64(output,0,total);for i:=0;i<n;i+=1{put64(output,8*(i+1),order[i])};return i64(bytes)
}
