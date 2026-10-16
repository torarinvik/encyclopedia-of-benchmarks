package peak_element
import "core:c"
peak :: proc(a:[^]i64,lo,hi,n:int)->i64{mid:=lo+(hi-lo)/2;if (mid==0||a[mid-1]<=a[mid])&&(mid==n-1||a[mid+1]<=a[mid]) do return i64(mid);if mid>0&&a[mid-1]>a[mid] do return peak(a,lo,mid-1,n);return peak(a,mid+1,hi,n)}
@(export)
peak_element :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>129||v[0]<1||v[0]>128||n!=c.size_t(v[0]+1) do return -1;count:=int(v[0]);for i:=0;i<count;i+=1{if v[i+1]<-2147483648||v[i+1]>2147483647 do return -1};return peak(&v[1],0,count-1,count)}
