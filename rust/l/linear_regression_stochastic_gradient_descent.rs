const INVALID:f64=-1.0e300;
/// Train a one-feature model with ordered per-observation gradient updates.
#[no_mangle]
pub unsafe extern "C" fn linear_regression_stochastic_gradient_descent(v:*const i64,length:usize)->f64{
 if v.is_null()||length<9||length>133{return INVALID;}let a=std::slice::from_raw_parts(v,length);let(n,epochs,rate,m0,b0)=(a[0],a[1],a[2],a[3],a[4]);
 if !(2..=64).contains(&n)||length!=5+2*n as usize||!(1..=200).contains(&epochs)||!(1..=10000).contains(&rate)||!(-10_000_000..=10_000_000).contains(&m0)||!(-10_000_000..=10_000_000).contains(&b0){return INVALID;}
 for i in 0..n as usize{let(x,y)=(a[5+2*i],a[6+2*i]);if !(-10_000_000..=10_000_000).contains(&x)||!(-100_000_000..=100_000_000).contains(&y){return INVALID;}}
 let alpha=rate as f64/1_000_000.0;let mut w=m0 as f64/1_000_000.0;let mut b=b0 as f64/1_000_000.0;
 for _ in 0..epochs{for i in 0..n as usize{let x=a[5+2*i] as f64/1_000_000.0;let y=a[6+2*i] as f64/1_000_000.0;let error=w*x+b-y;w-=alpha*(error*x/n as f64);b-=alpha*(error/n as f64);}}
 w
}
