#[no_mangle]
pub unsafe extern "C" fn tsvc_s221_partial_recursive_fused_update(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 257 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > 64.0 { return -1; }
    let n = rn as usize;
    if length != 1 + 4*n { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.fract() != 0.0 || x.abs() > 2.0) { return -1; }
    let required = 2*n;
    if output.is_null() || capacity < required { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, required) };
    for i in 0..n { out[i] = values[1+i]; out[n+i] = values[1+n+i]; }
    for i in 1..n {
        out[i] = out[i] + values[1+2*n+i] * values[1+3*n+i];
        out[n+i] = (out[n+i-1] + out[i]) + values[1+3*n+i];
    }
    required as i64
}
