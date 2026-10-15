const MAX_LENGTH:usize=64; const BOUND:i64=1_000_000;
#[no_mangle]
pub extern "C" fn is_arithmetic_series(values:*const i64,length:usize)->i64 {
 if values.is_null()||length==0||length>MAX_LENGTH{return -1;}
 let a=unsafe{std::slice::from_raw_parts(values,length)};
 if a.iter().any(|&x|x < -BOUND||x>BOUND){return -1;}
 if length==1{return 1;} let d=a[1]-a[0];
 for i in 1..length-1{if a[i+1]-a[i]!=d{return 0;}} 1
}
