package iterating_through_submasks
import "core:c"
@(export)
iterating_through_submasks :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=1||v[0]<1||v[0]>4095 do return -1;mask:=v[0];submask:=mask;count:=i64(0);for submask!=0{count+=1;submask=(submask-1)&mask};return count}
