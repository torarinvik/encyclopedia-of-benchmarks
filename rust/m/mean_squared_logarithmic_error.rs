const INVALID:f64=-1.0e300;const SCALE:f64=1_000_000.0;
#[no_mangle]
pub unsafe extern "C" fn mean_squared_logarithmic_error(values:*const i64,length:usize)->f64{
    if values.is_null() || length < 1 { return INVALID; } let n=unsafe{*values}; if !(1..=64).contains(&n){return INVALID;} let n=n as usize; if length!=1+2*n{return INVALID;}
    for i in 0..2*n {let x=unsafe{*values.add(1+i)};if x<-999999||x>1_000_000{return INVALID;}}
    let mut total=0.0; for i in 0..n {let t=unsafe{*values.add(1+i)} as f64/SCALE;let p=unsafe{*values.add(1+n+i)} as f64/SCALE;let d=(t.ln_1p()-p.ln_1p()); total+=d*d;} total/n as f64
}
