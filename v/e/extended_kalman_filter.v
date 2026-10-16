module extended_kalman_filter
const bad = -1.0e300
@[export: 'extended_kalman_filter']
pub fn extended_kalman_filter(v &i64, n usize) f64 {
 if unsafe { v == nil } || n<10 || n>17 {return bad}
 steps:=unsafe{v[0]};if steps<1||steps>8||n!=usize(9+steps){return bad}
 for i in 1..9 {value:=unsafe{v[i]};if value < -10000||value>10000{return bad}}
 for i in 9..n {value:=unsafe{v[i]};if value < -10000||value>10000{return bad}}
 sc:=1000.0;mut x:=f64(unsafe{v[1]})/sc;mut y:=f64(unsafe{v[2]})/sc;mut p00:=f64(unsafe{v[3]})/sc;mut p01:=f64(unsafe{v[4]})/sc;mut p11:=f64(unsafe{v[5]})/sc;q0:=f64(unsafe{v[6]})/sc;q1:=f64(unsafe{v[7]})/sc;r:=f64(unsafe{v[8]})/sc
 if unsafe{v[1]} < -2000||unsafe{v[1]}>2000||unsafe{v[2]} < -2000||unsafe{v[2]}>2000||p00<=0||p11<=0||p00*p11<=p01*p01||q0<0||q1<0||r<=0||r>10{return bad}
 for t in 0..int(steps){f01:=f64(.1);f10:=f64(.1)*x;nx:=x+f01*y;ny:=y+f64(.05)*x*x;a:=p00+2*f01*p01+f01*f01*p11+q0;b:=f10*p00+(1+f01*f10)*p01+f01*p11;c:=f10*f10*p00+2*f10*p01+p11+q1;x=nx;y=ny;p00=a;p01=b;p11=c
 h0:=f64(.1)*x;res:=f64(unsafe{v[9+t]})/sc-(f64(.05)*x*x+y);s:=h0*h0*p00+2*h0*p01+p11+r;if s<=0{return bad};k0:=(p00*h0+p01)/s;k1:=(p01*h0+p11)/s;x+=k0*res;y+=k1*res
 a00:=1-k0*h0;a01:=-k0;a10:=-k1*h0;a11:=1-k1;z00:=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r;z01:=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r;z11:=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r;p00=z00;p01=z01;p11=z11
 }
 return x
}
