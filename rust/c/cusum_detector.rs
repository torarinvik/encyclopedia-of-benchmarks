/// Two-sided CUSUM detector over a bounded integer-valued input domain.
fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset+8].copy_from_slice(&value.to_le_bytes());
}
#[no_mangle]
pub unsafe extern "C" fn cusum_detector(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let header = std::slice::from_raw_parts(input, 5);
    let n64=header[0];
    if !(0..=128).contains(&n64) { return -1; }
    let n=n64 as usize;
    if length != n+5 { return -1; }
    let packed=std::slice::from_raw_parts(input,length);
    let target=packed[1]; let sigma=packed[2]; let allowance=packed[3]; let threshold=packed[4];
    if !(-1000..=1000).contains(&target) || !(1..=1000).contains(&sigma) || !(0..=1000).contains(&allowance) || !(1..=1000).contains(&threshold) || packed[5..].iter().any(|v| !(-1000..=1000).contains(v)) { return -1; }
    if capacity<n*8 || (n>0 && output.is_null()) { return -2; }
    let mut upper=0.0f64; let mut lower=0.0f64;
    if n == 0 { return 0; }
    let out=std::slice::from_raw_parts_mut(output,n*8);
    for (i,&sample) in packed[5..].iter().enumerate() {
        let z=(sample as f64-target as f64)/sigma as f64;
        upper=(upper+z-allowance as f64).max(0.0);
        lower=(lower-z-allowance as f64).max(0.0);
        let signal=if upper>threshold as f64 { 1 } else if lower>threshold as f64 { -1 } else { 0 };
        if signal != 0 { upper=0.0; lower=0.0; }
        put_i64_le(out,i*8,signal);
    }
    (n*8) as i64
}
