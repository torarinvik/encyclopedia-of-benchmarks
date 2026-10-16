fn factorial(n:i64)->i64{let mut x=1;for i in 1..=n{x*=i}x}
#[no_mangle]
pub unsafe extern "C" fn permutation_calculation(v:*const i64,n:usize)->i64{if v.is_null()||n!=2{return -1}let a=std::slice::from_raw_parts(v,n);if !(0..=15).contains(&a[0])||a[1]<0||a[1]>a[0]{return -1}factorial(a[0])/factorial(a[0]-a[1])}
