#[no_mangle]
pub unsafe extern "C" fn unbias_01(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 257 { return -1; }
    let n=*input; if !(0..=256).contains(&n)||length!=n as usize+1{return -1;}
    let bits=std::slice::from_raw_parts(input.add(1),n as usize); if bits.iter().any(|&bit|bit!=0&&bit!=1){return -1;}
    for pair in bits.chunks_exact(2){if pair[0]!=pair[1]{return pair[0];}}
    -1
}
