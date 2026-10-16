#[no_mangle]
pub extern "C" fn kronecker_product(v:*const i64,n:usize)->i64{if n!=6||v.is_null(){return -1;}let a=unsafe{std::slice::from_raw_parts(v,n)};if a.iter().any(|&x|!(-10..=10).contains(&x)){return -1;}let x=[a[0]*a[4],a[0]*a[5],a[1]*a[4],a[1]*a[5],a[2]*a[4],a[2]*a[5],a[3]*a[4],a[3]*a[5]];x.iter().fold(0i64,|r,&z|r*201+z+100)}
