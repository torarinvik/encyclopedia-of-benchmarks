import math
fn put_double(mut outp &u8, offset int, value f64) { mut bits:=u64(math.bits_from_f64(value)); for b in 0..8 { unsafe { outp[offset+b]=u8(bits&255) }; bits >>= 8 } }
@[export: 'ordinary_least_squares_regression']
pub fn ordinary_least_squares_regression(v &i64,n usize,outp &u8,cap usize)i64 {
 if n<5{return -1};count:=unsafe{v[0]};if count<2||count>32||n!=usize(1+2*count){return -1}
 mut xs:=[32]f64{};mut ys:=[32]f64{};mut xm:=f64(0);mut ym:=f64(0)
 for i in 0..int(count){x:=unsafe{v[1+2*i]};y:=unsafe{v[2+2*i]};if x < -10000||x>10000||y < -10000||y>10000{return -1};xs[i]=f64(x);ys[i]=f64(y);xm+=xs[i];ym+=ys[i]}
 xm/=f64(count);ym/=f64(count);mut num:=f64(0);mut den:=f64(0)
 for i in 0..int(count){dx:=xs[i]-xm;num+=dx*(ys[i]-ym);den+=dx*dx}
 if den==0{return -1};slope:=num/den;intercept:=ym-slope*xm
 if cap<16||isnil(outp){return -2};put_double(mut outp,0,intercept);put_double(mut outp,8,slope);return 16
}
