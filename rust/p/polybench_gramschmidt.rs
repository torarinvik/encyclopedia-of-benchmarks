// Clean-room bounded PolyBench QR port. See package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn polybench_gramschmidt(input: *const f64, length: usize,
        output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let mv = *input;
    let nv = *input.add(1);
    if !mv.is_finite() || !nv.is_finite() || mv.fract() != 0.0 || nv.fract() != 0.0 ||
        mv < 1.0 || mv > 6.0 || nv < 1.0 || nv > 6.0 || nv > mv { return -1; }
    let m = mv as usize;
    let n = nv as usize;
    let q_cells = m*n;
    let r_cells = n*n;
    let total = q_cells+r_cells;
    if output.is_null() || capacity < total { return -2; }
    let mut a = [0.0f64;36];
    let mut q = [0.0f64;36];
    let mut r = [0.0f64;36];
    let mut staged = [0.0f64;72];
    for i in 0..m { for j in 0..n { a[i*n+j] = ((i*j)%m) as f64/m as f64*100.0+10.0; } }
    for k in 0..n {
        let mut norm_squared = 0.0;
        for i in 0..m { norm_squared += a[i*n+k]*a[i*n+k]; }
        r[k*n+k] = norm_squared.sqrt();
        for i in 0..m { q[i*n+k] = a[i*n+k]/r[k*n+k]; }
        for j in (k+1)..n {
            r[k*n+j] = 0.0;
            for i in 0..m { r[k*n+j] += q[i*n+k]*a[i*n+j]; }
            for i in 0..m { a[i*n+j] = a[i*n+j]-q[i*n+k]*r[k*n+j]; }
        }
    }
    staged[..r_cells].copy_from_slice(&r[..r_cells]);
    staged[r_cells..total].copy_from_slice(&q[..q_cells]);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, total);
    total as i64
}
