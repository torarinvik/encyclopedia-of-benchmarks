#[no_mangle]
pub unsafe extern "C" fn tsvc_vtvtv_triple_product_map(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 193 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > 64.0 { return -1; }
    let n = rn as usize;
    if length != 1 + 3*n { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.fract() != 0.0 || x.abs() > 2.0) { return -1; }
    if output.is_null() || capacity < n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, n) };
    for i in 0..n { out[i] = (values[1+i] * values[1+n+i]) * values[1+2*n+i]; }
    n as i64
}
