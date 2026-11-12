#[no_mangle]
pub unsafe extern "C" fn npb_sp_pentadiagonal_line_solve(
    input: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    const MIN_N: usize = 5;
    const MAX_N: usize = 16;
    if input.is_null() || !(1 + 6 * MIN_N..=1 + 6 * MAX_N).contains(&length) { return -1; }
    let n_value = *input;
    if !n_value.is_finite() || n_value.fract() != 0.0 || n_value < MIN_N as f64 || n_value > MAX_N as f64 { return -1; }
    let n = n_value as usize;
    if length != 1 + 6 * n { return -1; }
    let lower2 = std::slice::from_raw_parts(input.add(1), n);
    let lower1 = std::slice::from_raw_parts(input.add(1 + n), n);
    let diagonal = std::slice::from_raw_parts(input.add(1 + 2*n), n);
    let upper1 = std::slice::from_raw_parts(input.add(1 + 3*n), n);
    let upper2 = std::slice::from_raw_parts(input.add(1 + 4*n), n);
    let rhs = std::slice::from_raw_parts(input.add(1 + 5*n), n);
    if lower2[0] != 0.0 || lower2[1] != 0.0 || lower1[0] != 0.0 ||
        upper1[n-1] != 0.0 || upper2[n-2] != 0.0 || upper2[n-1] != 0.0 { return -1; }
    for row in 0..n {
        let bands = [lower2[row], lower1[row], upper1[row], upper2[row]];
        let mut radius = 0.0;
        for band in bands {
            if !band.is_finite() || band.abs() > 2.0 { return -1; }
            radius += band.abs();
        }
        if !diagonal[row].is_finite() || !(5.0..=16.0).contains(&diagonal[row]) ||
            !rhs[row].is_finite() || rhs[row].abs() > 64.0 || diagonal[row] - radius < 0.25 { return -1; }
    }
    if output.is_null() || capacity < n { return -2; }
    let mut lo1 = lower1.to_vec();
    let mut diag = diagonal.to_vec();
    let mut up1 = upper1.to_vec();
    let up2 = upper2.to_vec();
    let mut work_rhs = rhs.to_vec();
    let mut solution = vec![0.0; n];
    for pivot_row in 0..n {
        let pivot = diag[pivot_row];
        if pivot_row + 1 < n {
            let row = pivot_row + 1;
            let factor = lo1[row] / pivot;
            diag[row] -= factor * up1[pivot_row];
            up1[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
        if pivot_row + 2 < n {
            let row = pivot_row + 2;
            let factor = lower2[row] / pivot;
            lo1[row] -= factor * up1[pivot_row];
            diag[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
    }
    for row in (0..n).rev() {
        let mut value = work_rhs[row];
        if row + 1 < n { value -= up1[row] * solution[row + 1]; }
        if row + 2 < n { value -= up2[row] * solution[row + 2]; }
        solution[row] = value / diag[row];
    }
    std::ptr::copy_nonoverlapping(solution.as_ptr(), output, n);
    n as i64
}
