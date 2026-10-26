const MAX_N: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn tsvc_s275_column_conditional_axpy_recurrence(input: *const f64,
    length: usize, output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 193 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let rn = values[0];
    if !rn.is_finite() || rn.fract() != 0.0 || rn < 1.0 || rn > MAX_N as f64 { return -1; }
    let n = rn as usize;
    let cells = n * n;
    if length != 1 + 3 * cells { return -1; }
    if values[1..].iter().any(|x| !x.is_finite() || x.fract() != 0.0 || x.abs() > 16.0) { return -1; }
    if output.is_null() || capacity < cells { return -2; }
    let mut a = [0.0_f64; MAX_N * MAX_N];
    a[..cells].copy_from_slice(&values[1..1 + cells]);
    let bs = 1 + cells;
    let cs = 1 + 2 * cells;
    for col in 0..n {
        if a[col] > 0.0 {
            for row in 1..n {
                let index = row * n + col;
                a[index] = a[index - n] + values[bs + index] * values[cs + index];
            }
        }
    }
    unsafe { std::ptr::copy_nonoverlapping(a.as_ptr(), output, cells); }
    cells as i64
}
