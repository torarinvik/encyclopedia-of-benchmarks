module euler_modified
import math
fn put64(mut out &u8,slot int,x f64){bits:=math.bits_from_f64(x);for k in 0..8{unsafe{out[slot*8+k]=u8(bits&255)};bits>>=8}}
@[export:'euler_modified']
pub fn euler_modified(v &i64,n usize,mut out &u8,cap usize)i64{
 if unsafe{v==nil}||n!=2{return -1};steps:=unsafe{v[0]};y0:=unsafe{v[1]};if steps<1||steps>8||y0<1||y0>4{return -1}
 bytes:=(int(steps)+1)*8;if unsafe{out==nil}||cap<bytes{return -2}
 h:=f64(0.25);mut x:=f64(0);mut y:=f64(y0);put64(mut out,0,y)
 for i in 0..int(steps){f0:=-2.0*x*y*y;predictor:=y+h*f0;f1:=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(mut out,i+1,y)}
 return i64(bytes)
}
