const INVALID_RESULT:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn newton_raphson(values:*const i64,length:usize)->f64 {
    if values.is_null() || length!=2 { return INVALID_RESULT; }
    let a=std::slice::from_raw_parts(values,length); let n=a[0];let q=a[1];
    if !(2..=4).contains(&n)||!(4..=8).contains(&q){return INVALID_RESULT}
    let mut x=q as f64/4.0;for _ in 0..8{x=0.5*(x+n as f64/x);}x
}
