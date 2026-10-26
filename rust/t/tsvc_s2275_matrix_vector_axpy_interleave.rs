#[no_mangle]
pub unsafe extern "C" fn tsvc_s2275_matrix_vector_axpy_interleave(p:*const f64,l:usize,q:*mut f64,cap:usize)->i64{
 if p.is_null()||l<9||l>226{return -1}let x=unsafe{std::slice::from_raw_parts(p,l)};let rn=x[0];let rp=x[1];
 if !rn.is_finite()||rn.fract()!=0.0||rn<1.0||rn>8.0||!rp.is_finite()||rp.fract()!=0.0||rp<1.0||rp>8.0{return -1}
 let n=rn as usize;let passes=rp as usize;let ms=n*n;let out=ms+n;if l!=2+3*ms+4*n||x[2..].iter().any(|v|!v.is_finite()||v.fract()!=0.0||v.abs()>1.0){return -1}
 if q.is_null()||cap<out{return -2}let mut aa=[0.0;64];let mut a=[0.0;8];let bb=2+ms;let cc=2+2*ms;let vec=2+3*ms;for i in 0..ms{aa[i]=x[2+i]}for i in 0..n{a[i]=x[vec+i]}
 for _ in 0..passes{for i in 0..n{for j in 0..n{let k=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k]}a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i]}}
 let y=unsafe{std::slice::from_raw_parts_mut(q,out)};y[..ms].copy_from_slice(&aa[..ms]);y[ms..].copy_from_slice(&a[..n]);out as i64
}
