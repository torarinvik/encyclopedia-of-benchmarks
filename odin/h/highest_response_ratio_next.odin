package highest_response_ratio_next
import "core:c"
put64 :: proc(out: [^]u8,slot: int,value: i64){bits:=u64(value);for b:=0;b<8;b+=1{out[slot*8+b]=u8(bits>>(b*8))}}
@(export)
highest_response_ratio_next :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,capacity:c.size_t)->i64{
 if v==nil||n<3||n>129 do return -1;count:=v[0];if count<1||count>64||n!=c.size_t(1+2*count)do return -1
 a:[64]i64; b:[64]i64; tat:[64]i64; done:[64]bool
 for i:=0;i<int(count);i+=1{a[i]=v[1+2*i];b[i]=v[2+2*i];if a[i]<0||a[i]>100000||b[i]<1||b[i]>1000 do return -1}
 for i:=1;i<int(count);i+=1{j:=i;for j>0&&a[j]<a[j-1]{t:=a[j];a[j]=a[j-1];a[j-1]=t;t=b[j];b[j]=b[j-1];b[j-1]=t;j-=1}}
 if int(count)*8>int(capacity)||(count>0&&out==nil)do return -2;now:=i64(0);finished:=0
 for finished<int(count){best:=-1;best_num:=i64(0);for i:=0;i<int(count);i+=1{if !done[i]&&a[i]<=now{cand:=now-a[i]+b[i];if best<0||cand*b[best]>best_num*b[i]{best=i;best_num=cand}}};if best<0{for i:=0;i<int(count);i+=1{if !done[i]&&(best<0||a[i]<a[best])do best=i};now=a[best]}else{tat[best]=now+b[best]-a[best];now+=b[best];done[best]=true;finished+=1}}
 for i:=0;i<int(count);i+=1{put64(out,i,tat[i])};return count*8
}
