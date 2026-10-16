#[no_mangle]
pub extern "C" fn local_binary_pattern(v:*const i64,n:usize)->i64{if v.is_null()||n!=9{return -1;}let a=unsafe{std::slice::from_raw_parts(v,9)};if a.iter().any(|&x|!(0..=255).contains(&x)){return -1;}let ix=[2usize,5,1,8,7,6,3,0];let mut out=0i64;for i in 0..8{if a[ix[i]]>=a[4]{out|=1i64<<i;}}out}
