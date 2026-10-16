package modular_binary_exponentiation_recursive
import "core:c"
power :: proc(a,e,m:i64)->i64{if e==0 do return 1;if e%2==1 do return (power(a,e-1,m)*a)%m;h:=power(a,e/2,m);return (h*h)%m}
@(export)
modular_binary_exponentiation_recursive :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=3 do return -1;a:=v[0];e:=v[1];m:=v[2];if a<0||a>1000000||e<0||e>60||m<2||m>1000000 do return -1;return power(a,e,m)}
