#[no_mangle]
pub extern "C" fn last_item_in_a_list(v:*const i64,n:usize)->i64{if n>64||(n>0&&v.is_null()){return -1;}let a=if n==0{&[][..]}else{unsafe{std::slice::from_raw_parts(v,n)}};if a.iter().any(|&x|!(0..=100000).contains(&x)){return -1;}*a.last().unwrap_or(&-1)}
