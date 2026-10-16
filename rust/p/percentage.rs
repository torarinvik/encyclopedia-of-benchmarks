#[no_mangle]
pub unsafe extern "C" fn percentage(v:*const i64,n:usize)->i64{if v.is_null()||n!=3{return -1}let a=std::slice::from_raw_parts(v,n);if !(1..=100000).contains(&a[0])||!(1..=100000).contains(&a[1])||!(1..=4).contains(&a[2]){return -1}let scale=10i64.pow(a[2] as u32);let product=a[0]*a[1]*scale;if product<100{-1}else{product/100}}
