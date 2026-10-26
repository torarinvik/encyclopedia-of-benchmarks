module tsvc_s1279_nested_conditional_accumulation
import math
@[export:'tsvc_s1279_nested_conditional_accumulation']
pub fn tsvc_s1279_nested_conditional_accumulation(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<7||l>322{return -1}
 unsafe{rn:=x[0];rp:=x[1];if !rn.is_finite()||math.trunc(rn)!=rn||rn<1||rn>64||!rp.is_finite()||math.trunc(rp)!=rp||rp<1||rp>8{return -1};n:=int(rn);passes:=int(rp);if l!=usize(2+5*n){return -1}
 for i in 2..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(n){return -2};mut c:=[64]f64{};for i in 0..n{c[i]=x[2+2*n+i]}
 for _ in 0..passes{for i in 0..n{a:=x[2+i];b:=x[2+n+i];if a<0{if b>a{c[i]+=x[2+3*n+i]*x[2+4*n+i]}}}}
 for i in 0..n{y[i]=c[i]};return i64(n)}
}
