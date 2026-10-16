package power_iteration

import "core:math"

@(export)
power_iteration :: proc "c" (v: [^]i64, n: u64) -> f64 {
 if v==nil||n!=5 do return -1e300
 for i:=0;i<5;i+=1{if v[i]<1||v[i]>1000 do return -1e300}
 a,b,d:=f64(v[0]),f64(v[1]),f64(v[2]);if a*d<=b*b do return -1e300
 x,y,previous:=f64(v[3]),f64(v[4]),f64(0)
 for it:=0;it<100;it+=1{w0:=a*x+b*y;w1:=b*x+d*y;norm:=math.sqrt(w0*w0+w1*w1);if norm==0 do return -1e300;x=w0/norm;y=w1/norm;av0:=a*x+b*y;av1:=b*x+d*y;eig:=x*av0+y*av1;if math.abs(eig-previous)/eig<=1e-12||it==99 do return eig;previous=eig}
 return -1e300
}
