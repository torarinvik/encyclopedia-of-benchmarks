#[no_mangle]
pub unsafe extern "C" fn payback(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>129{return -2}let a=std::slice::from_raw_parts(v,n);if !(0..=128).contains(&a[0])||n!=a[0]as usize+1{return -2}let mut total=0i64;for(i,&x)in a[1..].iter().enumerate(){if !(-1_000_000..=1_000_000).contains(&x){return -2}total+=x;if total>=0{return i as i64}}-1}
