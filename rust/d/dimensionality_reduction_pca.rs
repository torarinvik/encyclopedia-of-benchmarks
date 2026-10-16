#[no_mangle]
pub unsafe extern "C" fn dimensionality_reduction_pca(input:*const f64,n:usize,output:*mut f64,cap:usize)->i64{
 if input.is_null()||n<7{return -1} let v=std::slice::from_raw_parts(input,n);
 if v[0]!=2.0||v[2]!=1.0||v[1].fract()!=0.0||!(2.0..=8.0).contains(&v[1])||n!=3+2*v[1] as usize{return -1}
 let m=v[1] as usize;let x=&v[3..3+m];let y=&v[3+m..];if x.iter().chain(y).any(|z|!z.is_finite()||z.abs()>1_000_000.0){return -1}
 let mx=x.iter().sum::<f64>()/m as f64;let my=y.iter().sum::<f64>()/m as f64;let(mut a,mut b,mut d)=(0.0,0.0,0.0);
 for i in 0..m{let dx=x[i]-mx;let dy=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy;}a/=m as f64;b/=m as f64;d/=m as f64;if b<=0.0||(a-d).abs()+b.abs()==0.0{return -1}
 let t=0.5*(2.0*b).atan2(a-d);let(vx,vy)=(t.cos(),t.sin());if output.is_null()||cap<m{return -2}let o=std::slice::from_raw_parts_mut(output,m);for i in 0..m{o[i]=vx*x[i]+vy*y[i]}m as i64
}
