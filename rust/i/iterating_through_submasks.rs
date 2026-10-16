#[no_mangle]
pub extern "C" fn iterating_through_submasks(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1;}let mask=unsafe{*v};if !(1..=4095).contains(&mask){return -1;}let mut submask=mask;let mut count=0;while submask!=0{count+=1;submask=(submask-1)&mask;}count}
