fn solve(v:&[i64],i:usize,target:i64,half:i64)->bool{if target==half{return true}if i>=v.len()||target>half{return false}solve(v,i+1,target+v[i],half)||solve(v,i+1,target,half)}
#[no_mangle]
pub unsafe extern "C" fn partition(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>17{return -1}let a=std::slice::from_raw_parts(v,n);if !(0..=16).contains(&a[0])||n!=a[0]as usize+1{return -1}let vals=&a[1..];if vals.iter().any(|&x|!(0..=1000).contains(&x)){return -1}let sum:i64=vals.iter().sum();if sum%2!=0{return 0}i64::from(solve(vals,0,0,sum/2))}
