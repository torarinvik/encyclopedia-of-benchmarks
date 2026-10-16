package runge_kutta_gills

import "core:c"
import "core:math"

INVALID :: -1.0e300
derivative :: proc "contextless" (id:i64,x,y:f64)->f64 { switch id {case 0:return y;case 1:return x;case 2:return x+y;case 3:return(x-y)/2.0;case:return 1.0+y*y} }
step :: proc "contextless" (id:i64,x,y,h:f64)->(f64,bool) {
	s:=math.sqrt(2.0);k1:=h*derivative(id,x,y);k2:=h*derivative(id,x+h/2.0,y+k1/2.0)
	k3:=h*derivative(id,x+h/2.0,y+(-0.5+1.0/s)*k1+(1.0-1.0/s)*k2);k4:=h*derivative(id,x+h,y-(1.0/s)*k2+(1.0+1.0/s)*k3)
	out:=y+(k1+(2.0-s)*k2+(2.0+s)*k3+k4)/6.0
	ok:=!math.is_nan_f64(k1)&&!math.is_inf_f64(k1)&&!math.is_nan_f64(k2)&&!math.is_inf_f64(k2)&&!math.is_nan_f64(k3)&&!math.is_inf_f64(k3)&&!math.is_nan_f64(k4)&&!math.is_inf_f64(k4)&&!math.is_nan_f64(out)&&!math.is_inf_f64(out)
	return out,ok
}
@(export)
runge_kutta_gills :: proc "c" (input:[^]i64,length:c.size_t)->f64 {
	if input==nil||length!=5 do return INVALID
	fid,ym,xm,hm,em:=input[0],input[1],input[2],input[3],input[4]
	if fid<0||fid>4||ym< -1000000||ym>1000000||xm< -1000000||xm>1000000||em< -1000000||em>1000000||hm<10000||hm>250000||em<=xm do return INVALID
	y,x,h,end:=f64(ym)/1000000.0,f64(xm)/1000000.0,f64(hm)/1000000.0,f64(em)/1000000.0
	if fid==4&&(x<0.0||y>0.0) do return INVALID
	steps:=int((end-x)/h);if steps<1||steps>64 do return INVALID
	for i:=0;i<steps;i+=1{next,ok:=step(fid,x,y,h);if !ok do return INVALID;y=next;x+=h;if math.is_nan_f64(x)||math.is_inf_f64(x) do return INVALID}
	return y
}
