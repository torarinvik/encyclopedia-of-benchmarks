#[no_mangle]
pub extern "C" fn ibits(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1;}let mut x=unsafe{*v};if x<0||x>=9_007_199_254_740_992{return -1;}let mut c=0;while x!=0{c+=1;x>>=1;}c}
