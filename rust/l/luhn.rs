/// Return 1 when an even-length decimal digit array passes the Luhn checksum.
#[no_mangle]
pub unsafe extern "C" fn luhn_validate(input:*const i64,length:usize)->i64{
    if input.is_null()||length<1{return -1;}
    let values=std::slice::from_raw_parts(input,length);let n=values[0];
    if !(2..=64).contains(&n)||n%2!=0||length!=n as usize+1{return -1;}
    let mut sum=0i64;
    for i in 0..n as usize{let mut digit=values[i+1];if !(0..=9).contains(&digit){return -1;}if i%2==0{digit*=2;if digit>9{digit-=9;}}sum+=digit;}
    if sum%10==0{1}else{0}
}
