package maclaurin
import "core:c"
import "core:math"
BAD :: -1.0e300
fact :: proc(n:i64)->f64{f:f64=1;for i:=i64(2);i<=n;i+=1{f*=f64(i)};return f}
term :: proc(m:i64,x:f64,i:i64)->f64{e:=i;s:f64=1;if m==1{e=2*i+1;if i%2!=0{s=-1}}else if m==2{e=2*i;if i%2!=0{s=-1}};if m==0{return math.pow_f64(x,f64(e))/fact(e)};return s/fact(e)*math.pow_f64(x,f64(e))}
@(export) maclaurin :: proc "c"(v:[^]i64,n:c.size_t)->f64{if v==nil||n!=3 do return BAD;m,xm,em:=v[0],v[1],v[2];if m<0||m>2||xm < -2000||xm>2000||em<1||em>250 do return BAD;x:=f64(xm)/1000.0;error:=f64(em)/1000.0;coefficient:f64=0;result:f64=0;for i:i64=0;i<32;i+=1{result+=coefficient;coefficient=term(m,x,i);if math.abs(coefficient)<=error do return result};return BAD}
