package modular_multiplicative_inverse
import "core:c"
@(export)
modular_multiplicative_inverse :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=2 do return -1;a:=v[0];m:=v[1];if m<2||m>1000000||a<0||a>=m do return -1;r0:=a;r1:=m;s0:=i64(1);s1:=i64(0);for r1!=0{q:=r0/r1;t:=r0-q*r1;r0=r1;r1=t;u:=s0-q*s1;s0=s1;s1=u};if r0==1 do return (s0%m+m)%m;return -1}
