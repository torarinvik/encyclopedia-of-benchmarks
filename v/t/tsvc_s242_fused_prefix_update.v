module tsvc_s242_fused_prefix_update
import math
@[export:'tsvc_s242_fused_prefix_update']
pub fn tsvc_s242_fused_prefix_update(x &f64,l usize,mut y &f64,cap usize)i64{if unsafe{x==nil}||l<7||l>259{return -1};unsafe{r:=x[0];if !r.is_finite()||math.trunc(r)!=r||r<1||r>64{return -1};n:=int(r);if l!=usize(3+4*n){return -1};for i in 1..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}};if y==nil||cap<usize(n){return -2};mut a:=[64]f64{};for i in 0..n{a[i]=x[3+i]};for i in 1..n{mut v:=a[i-1]+x[1];v+=x[2];v+=x[3+2*n+i];v+=x[3+3*n+i];v+=x[3+4*n+i];a[i]=v};for i in 0..n{y[i]=a[i]};return i64(n)}}
