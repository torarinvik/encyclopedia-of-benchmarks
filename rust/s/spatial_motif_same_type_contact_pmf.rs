const MAX_LENGTH: i64 = 16;
const MAX_SUPPORT: usize = 17;

fn choose_value(n: i64, k0: i64) -> i64 {
    if k0 < 0 || k0 > n { return 0; }
    let k = k0.min(n-k0);
    let mut result=1i64;
    for i in 1..=k { result=result*(n-k+i)/i; }
    result
}
fn gcd_value(mut a: i64, mut b: i64) -> i64 {
    while b!=0 { let r=a%b;a=b;b=r; }
    a
}
fn put_i64(out: &mut [u8], word: usize, value: i64) {
    out[word*8..word*8+8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn spatial_motif_same_type_contact_pmf(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null()||length!=3 { return -1; }
    let input=std::slice::from_raw_parts(input,length);
    let (l,x1,x2)=(input[0],input[1],input[2]);
    if !(1..=MAX_LENGTH).contains(&l)||x1<0||x1>l||x2<0||x2>l { return -1; }
    let low=0.max(x1+x2-l); let high=x1.min(x2);
    let denominator=choose_value(l,x2);
    let mut numerators=[0i64;MAX_SUPPORT];
    for i in low..=high { numerators[(i-low) as usize]=choose_value(x1,i)*choose_value(l-x1,x2-i); }
    let mut expected_num=x1*x2;let mut expected_den=l;
    let divisor=gcd_value(expected_num,expected_den);expected_num/=divisor;expected_den/=divisor;
    let count=(high-low+1) as usize;let bytes=(3+count+2)*8;
    if output.is_null()||capacity<bytes { return -2; }
    let out=std::slice::from_raw_parts_mut(output,bytes);
    put_i64(out,0,low);put_i64(out,1,high);put_i64(out,2,denominator);
    for i in 0..count {put_i64(out,3+i,numerators[i]);}
    put_i64(out,3+count,expected_num);put_i64(out,4+count,expected_den);
    bytes as i64
}
