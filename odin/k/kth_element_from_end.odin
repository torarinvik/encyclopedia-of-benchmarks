package kth_element_from_end
import "core:c"
@(export)
kth_element_from_end :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65{return -1};k:=v[0];if k<=0||k>=i64(n){return -1};for i in 1..<n{if v[i]<0||v[i]>100000{return -1}};return v[n-c.size_t(k)]}
