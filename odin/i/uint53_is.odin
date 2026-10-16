package uint53_is
import "core:c"
@(export)
uint53_is :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=1{return -1};if v[0]>=0&&v[0]<9007199254740992{return 1};return 0}
