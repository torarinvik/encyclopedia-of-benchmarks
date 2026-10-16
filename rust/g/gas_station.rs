/// Return a zero-based station index that completes the circuit, or -1.
#[no_mangle]
pub unsafe extern "C" fn gas_station(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 { return -2; }
    let n64=*input;
    if !(0..=128).contains(&n64) { return -2; }
    let n=n64 as usize;
    if length!=2*n+1 { return -2; }
    let values=std::slice::from_raw_parts(input,length);
    if values[1..].iter().any(|v| *v<0 || *v>1_000_000) { return -2; }
    let mut total=0i64; let mut current=0i64; let mut start=0usize;
    for i in 0..n {
        let net=values[1+i]-values[1+n+i]; total+=net; current+=net;
        if current<0 { start=i+1; current=0; }
    }
    if total<0 { return -1; }
    start as i64
}
