#[no_mangle]
pub unsafe extern "C" fn tsvc_s3251_forward_shifted_array_expansion(p:*const f64,l:usize,q:*mut f64,c:usize)->i64{
 if p.is_null()||l<6||l>321{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let r=x[0];if !r.is_finite()||r.fract()!=0.0||r<1.0||r>64.0{return -1}let n=r as usize;
 if l!=1+5*n||x[1..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>1.0){return -1}if q.is_null()||c<3*n{return -2}
 let(mut a,mut b,mut d)=([0.0;64],[0.0;64],[0.0;64]);for i in 0..n{a[i]=x[1+i];b[i]=x[1+n+i];d[i]=x[1+3*n+i];}
 for i in 0..n.saturating_sub(1){a[i+1]=b[i]+x[1+2*n+i];b[i]=x[1+2*n+i]*x[1+4*n+i];d[i]=a[i]*x[1+4*n+i];}
 let y=unsafe{std::slice::from_raw_parts_mut(q,3*n)};y[..n].copy_from_slice(&a[..n]);y[n..2*n].copy_from_slice(&b[..n]);y[2*n..].copy_from_slice(&d[..n]);(3*n)as i64
}
