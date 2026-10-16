#[no_mangle]
pub extern "C" fn uint53_is(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1;}let x=unsafe{*v};if x>=0&&x<9_007_199_254_740_992{1}else{0}}
