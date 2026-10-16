package log_two
import "core:c"
@(export)
log_two :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=1||v[0]<0||v[0]>2147483647{return -1};x:=v[0];r:=i64(0);for x>>1!=0{x=x>>1;r+=1};return r}
