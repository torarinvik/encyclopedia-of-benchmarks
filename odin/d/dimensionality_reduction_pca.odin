package dimensionality_reduction_pca
import "core:c"
import "core:math"
@(export)
dimensionality_reduction_pca :: proc "c" (v: [^]f64,n0:c.size_t,out:[^]f64,cap0:c.size_t) -> i64 {
 n:=int(n0);cap:=int(cap0)
 if n<7||v==nil||v[0]!=2||v[2]!=1||v[1]<2||v[1]>8||math.floor(v[1])!=v[1] { return -1 }
 m:=int(v[1]);if n!=3+2*m{return -1};x:[8]f64; y:[8]f64;mx:=0.0;my:=0.0
 for i:=0;i<m;i+=1 {x[i]=v[3+i];y[i]=v[3+m+i];if x[i]!=x[i]||y[i]!=y[i]||math.abs(x[i])>1e6||math.abs(y[i])>1e6{return -1};mx+=x[i];my+=y[i]};mx/=f64(m);my/=f64(m)
 a:=0.0;b:=0.0;d:=0.0;for i:=0;i<m;i+=1 {dx:=x[i]-mx;dy:=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy};a/=f64(m);b/=f64(m);d/=f64(m);if b<=0||math.abs(a-d)+math.abs(b)==0{return -1}
 t:=0.5*math.atan2(2*b,a-d);vx:=math.cos(t);vy:=math.sin(t);if out==nil||cap<m{return -2};for i:=0;i<m;i+=1{out[i]=vx*x[i]+vy*y[i]};return i64(m)
}
