/// Emit a bounded geometric term sequence as little-endian binary64 values.
#[no_mangle]
pub unsafe extern "C" fn geometric_series(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null()||length!=3{return -1}let x=std::slice::from_raw_parts(input,3);
    if !(0..=16).contains(&x[0])||!(1..=8).contains(&x[1])||!(1..=4).contains(&x[2]){return -1}
    let n=x[0] as usize;if capacity<n*8||(n>0&&output.is_null()){return -2}
    let mut term=x[1] as f64;let ratio=x[2] as f64;
    for i in 0..n{let bytes=term.to_le_bytes();std::ptr::copy_nonoverlapping(bytes.as_ptr(),output.add(i*8),8);term*=ratio;}
    (n*8) as i64
}
