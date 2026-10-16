const INVALID:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn pow_algorithm(v:*const i64,n:usize)->f64{if v.is_null()||n!=2{return INVALID}let a=std::slice::from_raw_parts(v,n);if a[0]<-1000||a[0]>1000||a[1]<-8||a[1]>12{return INVALID}let mut result=1.0f64;for _ in 1..=a[1]{result*=a[0] as f64}result}
