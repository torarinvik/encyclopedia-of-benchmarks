package minimum_window_substring
import "core:c"
@(export)
minimum_window_substring :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<3||n>258||v[0]<0||v[0]>128 do return -1;a:=int(v[0]);if n<c.size_t(a+2) do return -1;mm:=v[a+1];if mm<1||mm>128 do return -1;m:=int(mm);if n!=c.size_t(a+m+2) do return -1
 need:[128]int;for i:=0;i<a;i+=1{if v[i+1]<0||v[i+1]>127 do return -1};for i:=0;i<m;i+=1{c0:=v[a+2+i];if c0<0||c0>127 do return -1;need[int(c0)]+=1}
 left:=0;best:=a+1;start:=0;missing:=m;for right:=0;right<a;right+=1{c0:=int(v[right+1]);if need[c0]>0 do missing-=1;need[c0]-=1;for missing==0{length:=right-left+1;if length<best{best=length;start=left};x:=int(v[left+1]);need[x]+=1;left+=1;if need[x]>0 do missing+=1}}
 if best==a+1 do return 0;if c.size_t(best)>cap||(best>0&&out==nil) do return -2;for i:=0;i<best;i+=1{out[i]=u8(v[start+1+i])};return i64(best)
}
