#[no_mangle]
pub unsafe extern "C" fn parenthesis(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>129{return -1}let a=std::slice::from_raw_parts(v,n);if !(0..=128).contains(&a[0])||n!=a[0]as usize+1{return -1}let mut balance=0i64;for &x in &a[1..]{if !(0..=127).contains(&x){return -1}if x==40{balance+=1}else if x==41{balance-=1;if balance<0{return 0}}}i64::from(balance==0)}
