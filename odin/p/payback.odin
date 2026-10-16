package payback
import "core:c"
@(export)
payback :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n<1||n>129||v[0]<0||v[0]>128||n!=c.size_t(v[0]+1) do return -2
 total:=i64(0);for i:=1;i<int(n);i+=1{if v[i]<-1000000||v[i]>1000000 do return -2;total+=v[i];if total>=0 do return i64(i-1)};return -1
}
