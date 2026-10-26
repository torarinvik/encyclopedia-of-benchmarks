#[no_mangle]
pub unsafe extern "C" fn tsvc_s111_odd_index_neighbor_update(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 3 || length > 129 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > MAX_N as f64 { return -1; }
    let n = rn as usize;
    if length != 1 + 2 * n { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.fract() != 0.0 || x.abs() > 1000.0) { return -1; }
    if output.is_null() || capacity < n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, n) };
    out.copy_from_slice(&values[1..1 + n]);
    for i in (1..n).step_by(2) { out[i] = values[i] + values[1 + n + i]; }
    n as i64
}
