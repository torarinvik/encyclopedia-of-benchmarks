module tsvc_s1251_per_element_dual_update
import math
@[export:'tsvc_s1251_per_element_dual_update']
pub fn tsvc_s1251_per_element_dual_update(x &f64,l usize,mut y &f64,c usize)i64 {
 if unsafe{x==nil}||l<6||l>321{return -1}
 unsafe{r:=x[0];if !r.is_finite()||math.trunc(r)!=r||r<1||r>64{return -1};n:=int(r);if l!=usize(1+5*n){return -1}
 for i in 1..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||c<usize(2*n){return -2};mut a:=[64]f64{};mut b:=[64]f64{}
 for i in 0..n{saved:=x[1+n+i]+x[1+2*n+i];b[i]=x[1+i]+x[1+3*n+i];a[i]=saved*x[1+4*n+i]}
 for i in 0..n{y[i]=a[i];y[n+i]=b[i]};return i64(2*n)}
}
