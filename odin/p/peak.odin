package peak
import "core:c"
find_peak :: proc(a:[^]i64,lo,hi:int)->i64{m:=(hi-lo)/2;l:=a[lo+m-1];c0:=a[lo+m];r:=a[lo+m+1];if c0>l&&c0>r do return c0;if l<r{start:=m;if m==2 do start-=1;return find_peak(a,lo+start,hi)};finish:=m;if m==2 do finish+=1;return find_peak(a,lo,lo+finish)}
@(export)
peak :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<4||n>65||v[0]<3||v[0]>64||n!=c.size_t(v[0]+1) do return -1;length:=int(v[0]);p:=1;for i:=0;i<length;i+=1{if v[i+1]<-1_000_000||v[i+1]>1_000_000 do return -1};for p<length-1&&v[p+1]>v[p]{p+=1};if p==1||p>=length-1 do return -1;for i:=p;i<length-1;i+=1{if v[i+2]>=v[i+1] do return -1};return find_peak(&v[1],0,length)}

