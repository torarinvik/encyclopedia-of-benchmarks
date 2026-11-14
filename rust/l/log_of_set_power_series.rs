const P:i64=998_244_353;
#[no_mangle]
pub unsafe extern "C" fn log_of_set_power_series(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null() || !(2..=33).contains(&length) { return -1; }
    let f=std::slice::from_raw_parts(input,length);
    if !(0..=5).contains(&f[0]) { return -1; }
    let size=1usize << f[0];
    if length!=1+size || f[1]!=1 || f[1..].iter().any(|&v| !(0..P).contains(&v)) { return -1; }
    if output.is_null() || capacity<8*size { return -2; }
    let mut result=[0i64;32];
    for mask in 1..size {
        let pivot=mask & mask.wrapping_neg();
        let mut sub=(mask-1)&mask; let mut sum=0;
        while sub!=0 {
            if sub & pivot != 0 { sum=(sum+result[sub]*f[1+(mask^sub)])%P; }
            sub=(sub-1)&mask;
        }
        result[mask]=(f[1+mask]-sum+P)%P;
    }
    for (i,&value) in result[..size].iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*size) as i64
}
