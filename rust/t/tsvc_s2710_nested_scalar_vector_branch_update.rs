#[no_mangle]
pub unsafe extern "C" fn tsvc_s2710_nested_scalar_vector_branch_update(p:*const f64,l:usize,q:*mut f64,cap:usize)->i64{
 if p.is_null()||l<58||l>323{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let rn=x[0];let rp=x[1];let scalar=x[2];
 if !rn.is_finite()||rn.fract()!=0.0||rn<11.0||rn>64.0||!rp.is_finite()||rp.fract()!=0.0||rp<1.0||rp>8.0||!scalar.is_finite()||scalar.fract()!=0.0||scalar.abs()>1.0{return -1}
 let n=rn as usize;let passes=rp as usize;if l!=3+5*n||x[3..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>1.0){return -1}if q.is_null()||cap<3*n{return -2}
 let(mut a,mut b,mut c)=([0.0;64],[0.0;64],[0.0;64]);for i in 0..n{a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i];}
 for _ in 0..passes{for i in 0..n{let d=x[3+3*n+i];let e=x[3+4*n+i];if a[i]>b[i]{a[i]+=b[i]*d;c[i]+=d*d;}else{b[i]=a[i]+e*e;if scalar>0.0{c[i]=a[i]+d*d;}else{c[i]+=e*e;}}}}
 let y=unsafe{std::slice::from_raw_parts_mut(q,3*n)};y[..n].copy_from_slice(&a[..n]);y[n..2*n].copy_from_slice(&b[..n]);y[2*n..].copy_from_slice(&c[..n]);(3*n)as i64
}
