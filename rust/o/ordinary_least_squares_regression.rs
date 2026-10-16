#[no_mangle]
pub unsafe extern "C" fn ordinary_least_squares_regression(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<5{return -1}let count=*v as usize;if !(2..=32).contains(&count)||n!=1+2*count{return -1}let(mut xm,mut ym)=(0.0,0.0);let mut xs=[0.0;32];let mut ys=[0.0;32];
 for i in 0..count{let x=*v.add(1+2*i);let y=*v.add(2+2*i);if !(-10000..=10000).contains(&x)||!(-10000..=10000).contains(&y){return -1}xs[i]=x as f64;ys[i]=y as f64;xm+=xs[i];ym+=ys[i];}xm/=count as f64;ym/=count as f64;let(mut num,mut den)=(0.0,0.0);for i in 0..count{let dx=xs[i]-xm;num+=dx*(ys[i]-ym);den+=dx*dx;}if den==0.0{return -1}let slope=num/den;let intercept=ym-slope*xm;if out.is_null()||cap<16{return -2}let a=intercept.to_le_bytes();let b=slope.to_le_bytes();for i in 0..8{*out.add(i)=a[i];*out.add(8+i)=b[i];}16
}
