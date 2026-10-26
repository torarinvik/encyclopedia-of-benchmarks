module tsvc_s3251_forward_shifted_array_expansion
import math
@[export:'tsvc_s3251_forward_shifted_array_expansion']
pub fn tsvc_s3251_forward_shifted_array_expansion(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<6||l>321{return -1}
 unsafe{r:=x[0];if !r.is_finite()||math.trunc(r)!=r||r<1||r>64{return -1};n:=int(r);if l!=usize(1+5*n){return -1}
 for i in 1..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(3*n){return -2};mut a:=[64]f64{};mut b:=[64]f64{};mut d:=[64]f64{}
 for i in 0..n{a[i]=x[1+i];b[i]=x[1+n+i];d[i]=x[1+3*n+i]}
 for i in 0..n-1{a[i+1]=b[i]+x[1+2*n+i];b[i]=x[1+2*n+i]*x[1+4*n+i];d[i]=a[i]*x[1+4*n+i]}
 for i in 0..n{y[i]=a[i];y[n+i]=b[i];y[2*n+i]=d[i]};return i64(3*n)}
}
