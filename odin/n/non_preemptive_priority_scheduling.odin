package non_preemptive_priority_scheduling
import "core:c"
put :: proc(outp:[^]u8,i:int,x:i32){bits:=transmute(u32)x;for k:=0;k<4;k+=1{outp[i*4+k]=u8(bits>>u32(8*k))}}
@(export)
non_preemptive_priority_scheduling :: proc "c" (v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{if v==nil||n<4||v[0]<1||v[0]>10||n!=c.size_t(1+3*v[0]) do return -1;count:=int(v[0]);a,b,p:[10]int;done:[10]bool;for i:=0;i<count;i+=1{av,bv,pv:=v[1+3*i],v[2+3*i],v[3+3*i];if av<0||av>20||bv<1||bv>10||pv<0||pv>10 do return -1;for j:=0;j<i;j+=1{if p[j]==int(pv) do return -1};a[i],b[i],p[i]=int(av),int(bv),int(pv)};if outp==nil||cap<c.size_t(count*4) do return -2;now,z:=0,0;for z<count{pick:=-1;for i:=0;i<count;i+=1{if !done[i]&&a[i]<=now&&(pick<0||p[i]<p[pick]||(p[i]==p[pick]&&a[i]<a[pick])) do pick=i};if pick<0{next:=100000;for i:=0;i<count;i+=1{if !done[i]&&a[i]<next do next=a[i]};now=next;continue};done[pick]=true;put(outp,z,i32(pick));z+=1;now+=b[pick]};return i64(count*4)}
