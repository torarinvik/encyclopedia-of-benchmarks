package runge_kutta_fehlberg_45

import "core:c"
import "core:math"

INVALID :: -1.0e300
derivative :: proc "contextless" (id:i64,x,y:f64)->f64 { switch id {case 0:return y;case 1:return x;case 2:return x+y;case 3:return(x-y)/2.0;case:return 1.0+y*y} }
step :: proc "contextless" (id:i64,x,y,h:f64)->(f64,bool) {
	k1:=h*derivative(id,x,y);k2:=h*derivative(id,x+h/4.0,y+k1/4.0);k3:=h*derivative(id,x+(3.0/8.0)*h,y+(3.0/32.0)*k1+(9.0/32.0)*k2)
	k4:=h*derivative(id,x+(12.0/13.0)*h,y+(1932.0/2197.0)*k1-(7200.0/2197.0)*k2+(7296.0/2197.0)*k3)
	k5:=h*derivative(id,x+h,y+(439.0/216.0)*k1-8.0*k2+(3680.0/513.0)*k3-(845.0/4104.0)*k4)
	k6:=h*derivative(id,x+h/2.0,y-(8.0/27.0)*k1+2.0*k2-(3544.0/2565.0)*k3+(1859.0/4104.0)*k4-(11.0/40.0)*k5)
	out:=y+(16.0/135.0)*k1+(6656.0/12825.0)*k3+(28561.0/56430.0)*k4-(9.0/50.0)*k5+(2.0/55.0)*k6
	ok:=true
	for value in [7]f64{k1,k2,k3,k4,k5,k6,out}{if math.is_nan_f64(value)||math.is_inf_f64(value){ok=false}}
	return out,ok
}
@(export)
runge_kutta_fehlberg_45 :: proc "c" (input:[^]i64,length:c.size_t)->f64 {
	if input==nil||length!=5 do return INVALID
	fid,ym,xm,hm,em:=input[0],input[1],input[2],input[3],input[4]
	if fid<0||fid>4||ym< -1000000||ym>1000000||xm< -1000000||xm>1000000||em< -1000000||em>1000000||hm<10000||hm>250000||em<=xm do return INVALID
	y,x,h,end:=f64(ym)/1000000.0,f64(xm)/1000000.0,f64(hm)/1000000.0,f64(em)/1000000.0
	if fid==4&&(x<0.0||y>0.0) do return INVALID
	steps:=int((end-x)/h);if steps<1||steps>64 do return INVALID
	for i:=0;i<steps;i+=1{next,ok:=step(fid,x,y,h);if !ok do return INVALID;y=next;x=h+x;if math.is_nan_f64(x)||math.is_inf_f64(x) do return INVALID}
	return y
}
