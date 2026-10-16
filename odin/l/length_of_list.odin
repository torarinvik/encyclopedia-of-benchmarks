package length_of_list
import "core:c"
@(export)
length_of_list :: proc "c" (v:[^]i64,n:c.size_t)->i64{if n>64{return -1};for i in 0..<n{if v[i]<0||v[i]>100000{return -1}};return i64(n)}
