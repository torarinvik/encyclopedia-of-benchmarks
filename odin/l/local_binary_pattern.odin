package local_binary_pattern
import "core:c"
@(export)
local_binary_pattern :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=9{return -1};for i:=c.size_t(0);i<9;i+=1{if v[i]<0||v[i]>255{return -1}};ix:=[8]c.size_t{2,5,1,8,7,6,3,0};out:=i64(0);for i:=c.size_t(0);i<8;i+=1{if v[ix[i]]>=v[4]{out|=i64(1)<<i}};return out}
