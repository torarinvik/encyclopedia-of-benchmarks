module power_iteration

import math

@[export: 'power_iteration']
pub fn power_iteration(v &i64,n usize) f64 {
 if isnil(v)||n!=5{return -1e300}
 for i in 0..5{if v[i]<1||v[i]>1000{return -1e300}}
 a,b,d:=f64(v[0]),f64(v[1]),f64(v[2]);if a*d<=b*b{return -1e300}
 mut x:=f64(v[3]);mut y:=f64(v[4]);mut previous:=0.0
 for it in 0..100{w0:=a*x+b*y;w1:=b*x+d*y;norm:=math.sqrt(w0*w0+w1*w1);if norm==0{return -1e300};x=w0/norm;y=w1/norm;av0:=a*x+b*y;av1:=b*x+d*y;eig:=x*av0+y*av1;if math.abs(eig-previous)/eig<=1e-12||it==99{return eig};previous=eig}
 return -1e300
}
