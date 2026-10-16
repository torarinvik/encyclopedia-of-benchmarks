#[no_mangle]
pub unsafe extern "C" fn two_pointer(input: *const i64,length:usize)->i64{
 if input.is_null()||length<2||length>258{return -2;}let v=std::slice::from_raw_parts(input,length);let n=v[0];let target=v[1];
 if !(0..=256).contains(&n)||length!=n as usize+2||target<i32::MIN as i64||target>i32::MAX as i64{return -2;}
 let a=&v[2..];if a.iter().any(|&x|x<i32::MIN as i64||x>i32::MAX as i64)||a.windows(2).any(|w|w[0]>w[1]){return -2;}
 let(mut left,mut right)=(0usize,a.len().saturating_sub(1));while left<right{let sum=a[left]+a[right];if sum==target{return (left*256+right) as i64;}if sum<target{left+=1;}else{right-=1;}}-1
}
