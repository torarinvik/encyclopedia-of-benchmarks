package ic_555_timer
import "core:c"
@(export)
ic_555_timer :: proc "c" (v:[^]i64,n:c.size_t)->f64{if v==nil||n!=4 do return -1e300;m:=v[0];a:=v[1];b:=v[2];cval:=v[3];if (m!=0&&m!=1)||a<1||a>1000000||b<1||b>1000000||(m==0&&(cval<1||cval>1000000))||(m==1&&(cval<0||cval>1000000)) do return -1e300;if m==0{return (1.44/(f64(a+2*b)*f64(cval)))*1e6};return (f64(a+b)/f64(a+2*b))*100.0}
