package kth_next_greater_element
import "core:c"
@(export)
kth_next_greater_element :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>8{return -1};k:=v[0];if k<1||k>7{return -1};for q:=c.size_t(1);q<n;q+=1{if v[q]<-15||v[q]>15{return -1}};m:=n-1;count:=i64(0);for i:=c.size_t(0);i<m;i+=1{cur:=v[i+1];pos:=i+1;ok:=true;for z:=i64(0);z<k;z+=1{for pos<m&&v[pos+1]<=cur{pos+=1};if pos==m{ok=false;break};cur=v[pos+1];pos+=1};if ok{count+=1}};return count}
