package local_maximum_point
import "core:c"
@(export)
local_maximum_point :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>64{return -1};for i in 0..<n{if v[i]<-1000000||v[i]>1000000{return -1}};s:=c.size_t(0);e:=n-1;for{m:=s+(e-s)/2;if(m==0||v[m-1]<=v[m])&&(m==n-1||v[m+1]<=v[m]){return i64(m)};if m>0&&v[m-1]>v[m]{e=m-1}else{s=m+1}}}
