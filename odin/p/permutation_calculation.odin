package permutation_calculation
import "core:c"
factorial :: proc(n:i64)->i64{x:=i64(1);for i:=i64(1);i<=n;i+=1{x*=i};return x}
@(export)
permutation_calculation :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0] do return -1;return factorial(v[0])/factorial(v[0]-v[1])}
