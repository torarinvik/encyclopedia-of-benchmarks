package linear_diophantine_equations_solver
import "core:c"
@(export)
linear_diophantine_equations_solver :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
 if v==nil||n!=3{return -1};a:=v[0];b:=v[1];c0:=v[2]
 if a < -1000||a>1000||b < -1000||b>1000||c0 < -10000||c0>10000{return -1}
 if a==0&&b==0{if c0==0{return -3};return -2}
 if a==0{if c0%b==0{return 20000003*10000001+(c0/b+10000001)};return -2}
 if b==0{if c0%a==0{return (c0/a+10000001)*20000003+10000001};return -2}
 or:=a;r:=b;os:=i64(1);s:=i64(0);ot:=i64(0);t:=i64(1)
 for r!=0{q:=or/r;z:=or-q*r;or=r;r=z;z=os-q*s;os=s;s=z;z=ot-q*t;ot=t;t=z}
 if c0%or!=0{return -2};x:=os*(c0/or);y:=ot*(c0/or);return (x+10000001)*20000003+(y+10000001)
}
