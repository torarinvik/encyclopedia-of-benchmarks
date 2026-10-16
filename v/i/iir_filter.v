module iir_filter
import math
fn put64(mut out &u8,slot int,x f64){bits:=math.bits_from_f64(x);for k in 0..8{unsafe{out[slot*8+k]=u8(bits&255)};bits>>=8}}
@[export:'iir_filter']
pub fn iir_filter(v &i64,n usize,mut out &u8,cap usize)i64{
 if unsafe{v==nil}||n<7||n>26{return -1};order:=unsafe{v[0]};samples:=unsafe{v[1]}
 if order<1||order>3||samples<1||samples>16||n!=4+2*int(order)+int(samples){return -1}
 mut a:=[4]f64{};mut b:=[4]f64{};mut xh:=[3]f64{};mut yh:=[3]f64{}
 for i in 0..int(order)+1{av:=unsafe{v[2+i]};bv:=unsafe{v[3+int(order)+i]};if av < -500||av>2000||bv < -500||bv>500{return -1};a[i]=f64(av)/1000.0;b[i]=f64(bv)/1000.0}
 if a[0]<0.5{return -1}
 for i in 0..int(samples){x:=unsafe{v[4+2*int(order)+i]};if x < -1000||x>1000{return -1}}
 bytes:=int(samples)*8;if unsafe{out==nil}||cap<bytes{return -2}
 for s in 0..int(samples){x:=f64(unsafe{v[4+2*int(order)+s]})/1000.0;mut y:=f64(0);for i in 1..int(order)+1{y+=b[i]*xh[i-1]-a[i]*yh[i-1]};y=(y+b[0]*x)/a[0];mut i:=int(order);for i>1{i--;xh[i]=xh[i-1];yh[i]=yh[i-1]};xh[0]=x;yh[0]=y;put64(mut out,s,y)}
 return i64(bytes)
}
