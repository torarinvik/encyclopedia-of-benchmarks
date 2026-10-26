#[no_mangle]
pub unsafe extern "C" fn tsvc_s451_sincos_vector_map(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > 64.0 { return -1; }
    let n = rn as usize;
    if length != 1 + 2*n { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.abs() > 10.0) { return -1; }
    if output.is_null() || capacity < n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, n) };
    for i in 0..n { out[i] = values[1+i].sin() + values[1+n+i].cos(); }
    n as i64
}
