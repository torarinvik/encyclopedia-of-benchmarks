#[no_mangle]
pub unsafe extern "C" fn fresnel_diffract(ptr:*const f64,n:usize,out:*mut f64,cap:usize)->i64{
 if ptr.is_null()||n!=12{return -1}let v=std::slice::from_raw_parts(ptr,n);
 if v[0]!=4.0||v[1]!=1.0||v[2]!=1.0||v[3]!=16.0||v[4..].iter().any(|x|!x.is_finite()||x.abs()>100.0){return -1}
 if out.is_null()||cap<8{return -2}
 let xr=[v[6],v[7],v[4],v[5]];let xi=[v[10],v[11],v[8],v[9]];let cr=[1.0,0.0,-1.0,0.0];let si=[0.0,-1.0,0.0,1.0];let mut fr=[0.0;4];let mut fi=[0.0;4];
 for k in 0..4{for j in 0..4{let t=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t];}}
 for k in (1..4).step_by(2){fr[k]=-fr[k];fi[k]=-fi[k];}
 let mut zr=[0.0;4];let mut zi=[0.0;4];for j in 0..4{for k in 0..4{let t=(k*j)&3;let s=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25;}}
 let result=[zr[2],zr[3],zr[0],zr[1],zi[2],zi[3],zi[0],zi[1]];std::slice::from_raw_parts_mut(out,8).copy_from_slice(&result);8
}
