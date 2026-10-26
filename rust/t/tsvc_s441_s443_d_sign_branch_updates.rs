#[no_mangle]
pub unsafe extern "C" fn tsvc_s441_s443_d_sign_branch_updates(p:*const f64,l:usize,q:*mut f64,cap:usize)->i64{
 if p.is_null()||l<7||l>259{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let rm=x[0];let rn=x[1];let rp=x[2];
 if !rm.is_finite()||rm.fract()!=0.0||(rm!=0.0&&rm!=1.0)||!rn.is_finite()||rn.fract()!=0.0||rn<1.0||rn>64.0||!rp.is_finite()||rp.fract()!=0.0||rp<1.0||rp>8.0{return -1}
 let mode=rm as usize;let n=rn as usize;let passes=rp as usize;if l!=3+4*n||x[3..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>1.0){return -1}
 if q.is_null()||cap<n{return -2}let mut a=[0.0;64];let b=3+n;let c=3+2*n;let d=3+3*n;for i in 0..n{a[i]=x[3+i]}
 for _ in 0..passes{for i in 0..n{if mode==0{if x[d+i]<0.0{a[i]+=x[b+i]*x[c+i]}else if x[d+i]==0.0{a[i]+=x[b+i]*x[b+i]}else{a[i]+=x[c+i]*x[c+i]}}else if x[d+i]<=0.0{a[i]+=x[b+i]*x[c+i]}else{a[i]+=x[b+i]*x[b+i]}}}
 let y=unsafe{std::slice::from_raw_parts_mut(q,n)};y.copy_from_slice(&a[..n]);n as i64
}
