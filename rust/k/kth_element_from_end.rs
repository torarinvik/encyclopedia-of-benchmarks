#[no_mangle]
pub extern "C" fn kth_element_from_end(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>65{return -1;}let x=unsafe{std::slice::from_raw_parts(v,n)};let k=x[0];if k<=0||k as usize>=n||x[1..].iter().any(|&z|!(0..=100000).contains(&z)){return -1;}x[n-k as usize]}
