const MAX_LENGTH:usize=64;const MAX_ABS_VALUE:i64=1_000_000;const INVALID_RESULT:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn welfords_variance(values:*const i64,length:usize)->f64{
 if values.is_null()||length<2||length>MAX_LENGTH{return INVALID_RESULT;}let input=std::slice::from_raw_parts(values,length);let(mut mean,mut m2)=(0.0f64,0.0f64);for(i,&x)in input.iter().enumerate(){if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&x){return INVALID_RESULT;}let delta=x as f64-mean;mean+=delta/(i+1)as f64;m2+=delta*(x as f64-mean);}m2/(length-1)as f64
}
