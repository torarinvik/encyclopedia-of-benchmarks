const MAX_LENGTH:usize=64; const BOUND:i64=1_000_000; const INVALID:f64=-1.0e300;
#[no_mangle]
pub extern "C" fn arithmetic_mean(values:*const i64,length:usize)->f64 {
 if values.is_null()||length==0||length>MAX_LENGTH{return INVALID;}
 let a=unsafe{std::slice::from_raw_parts(values,length)}; let mut total=0_i64;
 for &x in a{if x < -BOUND||x>BOUND{return INVALID;} total+=x;} total as f64/length as f64
}
