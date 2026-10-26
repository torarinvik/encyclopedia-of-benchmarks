module tsvc_s2275_matrix_vector_axpy_interleave
import math
@[export:'tsvc_s2275_matrix_vector_axpy_interleave']
pub fn tsvc_s2275_matrix_vector_axpy_interleave(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<9||l>226{return -1}
 unsafe{rn:=x[0];rp:=x[1];if !rn.is_finite()||math.trunc(rn)!=rn||rn<1||rn>8||!rp.is_finite()||math.trunc(rp)!=rp||rp<1||rp>8{return -1};n:=int(rn);passes:=int(rp);ms:=n*n;out:=ms+n;if l!=usize(2+3*ms+4*n){return -1}
 for i in 2..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(out){return -2};mut aa:=[64]f64{};mut a:=[8]f64{};bb:=2+ms;cc:=2+2*ms;vec:=2+3*ms;for i in 0..ms{aa[i]=x[2+i]}for i in 0..n{a[i]=x[vec+i]}
 for _ in 0..passes{for i in 0..n{for j in 0..n{k:=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k]}a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i]}}
 for i in 0..ms{y[i]=aa[i]}for i in 0..n{y[ms+i]=a[i]};return i64(out)}
}
