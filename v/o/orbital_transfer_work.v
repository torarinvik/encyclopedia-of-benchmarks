import math
fn put_double(mut outp &u8,x f64){mut bits:=u64(math.bits_from_f64(x));for k in 0..8{unsafe{outp[k]=u8(bits&255)};bits>>=8}}
@[export:'orbital_transfer_work']
pub fn orbital_transfer_work(v &i64,n usize,outp &u8,cap usize)i64{if n!=4{return -1};a:=unsafe{v[0]};b:=unsafe{v[1]};r1:=unsafe{v[2]};r2:=unsafe{v[3]};if a < -1000000000||a>1000000000||b < -1000000||b>1000000||r1<1||r1>1000000000||r2<1||r2>1000000000{return -1};if cap<8||isnil(outp){return -2};work:=(6.67430e-11*f64(a)*f64(b)/2.0)*(1.0/f64(r1)-1.0/f64(r2));put_double(mut outp,work);return 8}
