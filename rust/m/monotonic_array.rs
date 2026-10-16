use std::slice;
#[no_mangle]
pub extern "C" fn monotonic_array(v:*const i64,n:usize)->i64{
 if n>256|| (v.is_null()&&n>0){return -1}
 if n==0{return 1}let a=unsafe{slice::from_raw_parts(v,n)};
 if a.iter().any(|x|*x< -1_000_000_000||*x>1_000_000_000){return -1}
 let(inc,dec)=a.windows(2).fold((true,true),|(up,down),w|(up&&w[0]<=w[1],down&&w[0]>=w[1]));if inc||dec{1}else{0}
}
