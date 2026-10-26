module tsvc_s482_break_after_update
import math
@[export:'tsvc_s482_break_after_update']
pub fn tsvc_s482_break_after_update(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<5||l>194{return -1}
 unsafe{rn:=x[0];rp:=x[1];if !rn.is_finite()||math.trunc(rn)!=rn||rn<1||rn>64||!rp.is_finite()||math.trunc(rp)!=rp||rp<1||rp>8{return -1};n:=int(rn);passes:=int(rp);if l!=usize(2+3*n){return -1}
 for i in 2..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(n){return -2};mut a:=[64]f64{};bb:=2+n;cc:=2+2*n;for i in 0..n{a[i]=x[2+i]}
 for _ in 0..passes{for i in 0..n{a[i]+=x[bb+i]*x[cc+i];if x[cc+i]>x[bb+i]{break}}}
 for i in 0..n{y[i]=a[i]};return i64(n)}
}
