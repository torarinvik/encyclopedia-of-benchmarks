package list_scheduling
import "core:c"
MAX_M::8;MAX_N::32;MAX_INPUT::34
put64::proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
list_scheduling::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1
 m64,n64:=input[0],input[1]
 if m64<1||m64>MAX_M||n64<1||n64>MAX_N||length!=c.size_t(2+n64) do return -1
 m,n:=int(m64),int(n64)
 for i:=0;i<n;i+=1{if input[2+i]<1||input[2+i]>10000 do return -1}
 bytes:=8*(1+n+m);if output==nil||capacity<c.size_t(bytes) do return -2
 load:[MAX_M]i64;assign:[MAX_N]i64
 for i:=0;i<n;i+=1{best:=0;for j:=1;j<m;j+=1{if load[j]<load[best]{best=j}};assign[i]=i64(best);load[best]+=input[2+i]}
 span:=load[0];for j:=1;j<m;j+=1{if load[j]>span{span=load[j]}}
 put64(output,0,span);for i:=0;i<n;i+=1{put64(output,8*(1+i),assign[i])};for j:=0;j<m;j+=1{put64(output,8*(1+n+j),load[j])};return i64(bytes)
}
