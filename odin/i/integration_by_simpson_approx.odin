package integration_by_simpson_approx
import "core:c"
round_even :: proc(x:f64,p:int)->f64 {scale:=f64(1);for _ in 0..<p {scale*=10};y:=x*scale;lower:=i64(y);fraction:=y-f64(lower);if fraction>0.5||(fraction==0.5&&lower%2!=0){lower+=1};return f64(lower)/scale}
@(export)
integration_by_simpson_approx :: proc "c" (v:[^]i64,n:c.size_t)->f64 {if v==nil||n!=3 do return -1.0e300;a,b,p:=v[0],v[1],v[2];if a < -10||a>10||b < -10||b>10||a>=b||p<0||p>4 do return -1.0e300;h:=f64(b-a)/1000.0;total:=f64(a*a)+f64(b*b);for i in 1..<1000{x:=f64(a)+h*f64(i);if i%2==1{total+=x*x*4.0}else{total+=x*x*2.0}};total*=h/3.0;return round_even(total,int(p))}
