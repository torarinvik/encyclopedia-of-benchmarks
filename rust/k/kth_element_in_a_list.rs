#[no_mangle]
pub extern "C" fn kth_element_in_a_list(v:*const i64,n:usize)->i64{if n<3||n>34||v.is_null(){return -1;}let a=unsafe{std::slice::from_raw_parts(v,n)};let k=a[0];let pos=a[1];if k<1||k>16||n!=k as usize+2||pos<1||pos>k{return -1;}if a[2..].iter().any(|&x|!(-10000..=10000).contains(&x)){return -1;}a[pos as usize+1]}
