#[no_mangle]
pub unsafe extern "C" fn tsvc_s482_break_after_update(p:*const f64,l:usize,q:*mut f64,cap:usize)->i64{
 if p.is_null()||l<5||l>194{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let rn=x[0];let rp=x[1];
 if !rn.is_finite()||rn.fract()!=0.0||rn<1.0||rn>64.0||!rp.is_finite()||rp.fract()!=0.0||rp<1.0||rp>8.0{return -1}
 let n=rn as usize;let passes=rp as usize;if l!=2+3*n||x[2..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>1.0){return -1}
 if q.is_null()||cap<n{return -2}let mut a=[0.0;64];let b=2+n;let c=2+2*n;for i in 0..n{a[i]=x[2+i]}
 for _ in 0..passes{for i in 0..n{a[i]+=x[b+i]*x[c+i];if x[c+i]>x[b+i]{break}}}
 let y=unsafe{std::slice::from_raw_parts_mut(q,n)};y.copy_from_slice(&a[..n]);n as i64
}
