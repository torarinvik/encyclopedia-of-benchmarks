module dimensionality_reduction_pca
import math
@[export: 'dimensionality_reduction_pca']
pub fn dimensionality_reduction_pca(v &f64,n usize,mut out &f64,cap usize)i64{
 unsafe {
  if v==nil||n<7||v[0]!=2||v[2]!=1||v[1]<2||v[1]>8||math.floor(v[1])!=v[1]{return -1};m:=int(v[1]);if n!=usize(3+2*m){return -1}
  mut x:=[8]f64{};mut y:=[8]f64{};mut mx:=0.0;mut my:=0.0
  for i in 0..m{x[i]=v[3+i];y[i]=v[3+m+i];if x[i]!=x[i]||y[i]!=y[i]||math.abs(x[i])>1e6||math.abs(y[i])>1e6{return -1};mx+=x[i];my+=y[i]};mx/=f64(m);my/=f64(m)
  mut a:=0.0;mut b:=0.0;mut d:=0.0;for i in 0..m{dx:=x[i]-mx;dy:=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy};a/=f64(m);b/=f64(m);d/=f64(m);if b<=0||math.abs(a-d)+math.abs(b)==0{return -1}
  t:=0.5*math.atan2(2*b,a-d);vx:=math.cos(t);vy:=math.sin(t);if out==nil||cap<usize(m){return -2};for i in 0..m{out[i]=vx*x[i]+vy*y[i]};return i64(m)
 }
}
