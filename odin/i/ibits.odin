package ibits
import "core:c"
@(export)
ibits :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=1{return -1};x:=v[0];if x<0||x>=9007199254740992{return -1};count:=i64(0);for x!=0{count+=1;x=x>>1};return count}
