package extended_kalman_filter
import "core:c"
BAD :: -1.0e300
@(export)
extended_kalman_filter :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
 if v==nil||n<10||n>17 do return BAD
 steps:=v[0];if steps<1||steps>8||n!=c.size_t(9+steps) do return BAD
 for i:=c.size_t(1);i<9;i+=1 {if v[i]<-10000||v[i]>10000 do return BAD}
 for i:=c.size_t(9);i<n;i+=1 {if v[i]<-10000||v[i]>10000 do return BAD}
 sc:=f64(1000);x:=f64(v[1])/sc;y:=f64(v[2])/sc;p00:=f64(v[3])/sc;p01:=f64(v[4])/sc;p11:=f64(v[5])/sc;q0:=f64(v[6])/sc;q1:=f64(v[7])/sc;r:=f64(v[8])/sc
 if v[1]<-2000||v[1]>2000||v[2]<-2000||v[2]>2000||p00<=0||p11<=0||p00*p11<=p01*p01||q0<0||q1<0||r<=0||r>10 do return BAD
 for t:=i64(0);t<steps;t+=1 {
 f01:=f64(.1);f10:=f64(.1)*x;nx:=x+f01*y;ny:=y+f64(.05)*x*x;a:=p00+2*f01*p01+f01*f01*p11+q0;b:=f10*p00+(1+f01*f10)*p01+f01*p11;cc:=f10*f10*p00+2*f10*p01+p11+q1;x=nx;y=ny;p00=a;p01=b;p11=cc
 h0:=f64(.1)*x;res:=f64(v[c.size_t(9+t)])/sc-(f64(.05)*x*x+y);ss:=h0*h0*p00+2*h0*p01+p11+r;if ss<=0 do return BAD
 k0:=(p00*h0+p01)/ss;k1:=(p01*h0+p11)/ss;x+=k0*res;y+=k1*res
 a00:=1-k0*h0;a01:=-k0;a10:=-k1*h0;a11:=1-k1;z00:=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r;z01:=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r;z11:=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r;p00=z00;p01=z01;p11=z11
 }
 return x
}
