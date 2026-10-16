const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn in_static_equilibrium(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 5 { return INVALID_RESULT; }
    let n_value = unsafe { *values };
    if !(1..=100).contains(&n_value) || length != 1 + 4 * n_value as usize { return INVALID_RESULT; }
    let n = n_value as usize;
    let mut total_moment = 0_i64;
    for i in 0..n {
        let fx = unsafe { *values.add(1 + i) };
        let fy = unsafe { *values.add(1 + n + i) };
        let lx = unsafe { *values.add(1 + 2 * n + i) };
        let ly = unsafe { *values.add(1 + 3 * n + i) };
        if [fx, fy, lx, ly].iter().any(|&v| !(-1000..=1000).contains(&v)) { return INVALID_RESULT; }
        total_moment += lx * fy - ly * fx;
    }
    if total_moment == 0 { 1 } else { 0 }
}
