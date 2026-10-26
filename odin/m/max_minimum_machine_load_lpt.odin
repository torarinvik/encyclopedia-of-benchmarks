package max_minimum_machine_load_lpt
import "core:c"
N :: 16
put64 :: proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
max_minimum_machine_load_lpt :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>18 do return -1
 nr:=input[0];mr:=input[1];if nr<1||nr>16||mr<1||mr>4||length!=c.size_t(2+nr) do return -1
 n:=int(nr);m:=int(mr);p:[N]i64;order:[N]i64;assign:[N]i64;loads:[4]i64
 for i:=0;i<n;i+=1{p[i]=input[2+i];if p[i]<1||p[i]>100 do return -1;order[i]=i64(i)}
 bytes:=8*(1+n+m);if output==nil||capacity<c.size_t(bytes) do return -2
 for i:=1;i<n;i+=1{key:=order[i];j:=i;for j>0{prev:=int(order[j-1]);k:=int(key);if p[k]>p[prev]||(p[k]==p[prev]&&k<prev){order[j]=order[j-1];j-=1}else{break}};order[j]=key}
 for i:=0;i<n;i+=1{job:=int(order[i]);machine:=0;for j:=1;j<m;j+=1{if loads[j]<loads[machine]{machine=j}};assign[job]=i64(machine);loads[machine]+=p[job]}
 low:=loads[0];for j:=1;j<m;j+=1{if loads[j]<low{low=loads[j]}};put64(output,0,low);for i:=0;i<n;i+=1{put64(output,8*(1+i),assign[i])};for j:=0;j<m;j+=1{put64(output,8*(1+n+j),loads[j])};return i64(bytes)
}
