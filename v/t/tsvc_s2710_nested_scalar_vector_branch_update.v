module tsvc_s2710_nested_scalar_vector_branch_update
import math
@[export:'tsvc_s2710_nested_scalar_vector_branch_update']
pub fn tsvc_s2710_nested_scalar_vector_branch_update(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<58||l>323{return -1}
 unsafe{rn:=x[0];rp:=x[1];scalar:=x[2];if !rn.is_finite()||math.trunc(rn)!=rn||rn<11||rn>64||!rp.is_finite()||math.trunc(rp)!=rp||rp<1||rp>8||!scalar.is_finite()||math.trunc(scalar)!=scalar||math.abs(scalar)>1{return -1};n:=int(rn);passes:=int(rp);if l!=usize(3+5*n){return -1}
 for i in 3..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(3*n){return -2};mut a:=[64]f64{};mut b:=[64]f64{};mut c:=[64]f64{};for i in 0..n{a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i]}
 for _ in 0..passes{for i in 0..n{d:=x[3+3*n+i];e:=x[3+4*n+i];if a[i]>b[i]{a[i]+=b[i]*d;c[i]+=d*d}else{b[i]=a[i]+e*e;if scalar>0{c[i]=a[i]+d*d}else{c[i]+=e*e}}}}
 for i in 0..n{y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i]};return i64(3*n)}
}
