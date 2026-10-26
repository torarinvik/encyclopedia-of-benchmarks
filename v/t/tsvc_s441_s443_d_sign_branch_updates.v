module tsvc_s441_s443_d_sign_branch_updates
import math
@[export:'tsvc_s441_s443_d_sign_branch_updates']
pub fn tsvc_s441_s443_d_sign_branch_updates(x &f64,l usize,mut y &f64,cap usize)i64{
 if unsafe{x==nil}||l<7||l>259{return -1}
 unsafe{mr:=x[0];rn:=x[1];rp:=x[2];if !mr.is_finite()||math.trunc(mr)!=mr||(mr!=0&&mr!=1)||!rn.is_finite()||math.trunc(rn)!=rn||rn<1||rn>64||!rp.is_finite()||math.trunc(rp)!=rp||rp<1||rp>8{return -1};mode:=int(mr);n:=int(rn);passes:=int(rp);if l!=usize(3+4*n){return -1}
 for i in 3..int(l){if !x[i].is_finite()||math.trunc(x[i])!=x[i]||math.abs(x[i])>1{return -1}}
 if y==nil||cap<usize(n){return -2};mut a:=[64]f64{};bb:=3+n;cc:=3+2*n;dd:=3+3*n;for i in 0..n{a[i]=x[3+i]}
 for _ in 0..passes{for i in 0..n{if mode==0{if x[dd+i]<0{a[i]+=x[bb+i]*x[cc+i]}else if x[dd+i]==0{a[i]+=x[bb+i]*x[bb+i]}else{a[i]+=x[cc+i]*x[cc+i]}}else if x[dd+i]<=0{a[i]+=x[bb+i]*x[cc+i]}else{a[i]+=x[bb+i]*x[bb+i]}}}
 for i in 0..n{y[i]=a[i]};return i64(n)}
}
