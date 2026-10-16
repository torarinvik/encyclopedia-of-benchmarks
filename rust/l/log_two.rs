#[no_mangle]
pub extern "C" fn log_two(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1;}let mut x=unsafe{*v};if !(0..=2147483647).contains(&x){return -1;}let mut r=0;while x>>1!=0{x>>=1;r+=1;}r}
