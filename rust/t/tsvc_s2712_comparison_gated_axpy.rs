#[no_mangle]
pub unsafe extern "C" fn tsvc_s2712_comparison_gated_axpy(p:*const f64,l:usize,q:*mut f64,c:usize)->i64{
 if p.is_null()||l<5||l>194{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let rn=x[0];let rp=x[1];if !rn.is_finite()||rn.fract()!=0.0||rn<1.0||rn>64.0||!rp.is_finite()||rp.fract()!=0.0||rp<1.0||rp>8.0{return -1}let n=rn as usize;let passes=rp as usize;
 if l!=2+3*n||x[2..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>2.0){return -1}if q.is_null()||c<n{return -2}let mut a=[0.0;64];a[..n].copy_from_slice(&x[2..2+n]);
 for _ in 0..passes{for i in 0..n{let b=x[2+n+i];if a[i]>b{a[i]+=b*x[2+2*n+i];}}}let y=unsafe{std::slice::from_raw_parts_mut(q,n)};y.copy_from_slice(&a[..n]);n as i64
}
