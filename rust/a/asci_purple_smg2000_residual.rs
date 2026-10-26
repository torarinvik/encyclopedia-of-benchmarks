// Clean-room bounded residual profile; see package README and RIGHTS.md.
#[no_mangle]
pub unsafe extern "C" fn asci_purple_smg2000_residual(
    input: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    if input.is_null() || !(19..=253).contains(&length) { return -1; }
    for q in 0..3 {
        let v = *input.add(q);
        if !v.is_finite() || v.fract() != 0.0 || !(2.0..=5.0).contains(&v) { return -1; }
    }
    let nx = *input as usize;
    let ny = *input.add(1) as usize;
    let nz = *input.add(2) as usize;
    let cells = nx * ny * nz;
    if length != 3 + 2 * cells { return -1; }
    for q in 3..length {
        let v = *input.add(q);
        if !v.is_finite() || v.fract() != 0.0 || !(-1000.0..=1000.0).contains(&v) { return -1; }
    }
    if output.is_null() || capacity < cells { return -2; }
    let (si, sj) = (ny * nz, nz);
    for i in 0..nx { for j in 0..ny { for k in 0..nz {
        let q = i * si + j * sj + k;
        let x = *input.add(3 + q) as i64;
        let mut ax = 222 * x;
        if i > 0 { ax -= *input.add(3 + q - si) as i64; }
        if i + 1 < nx { ax -= *input.add(3 + q + si) as i64; }
        if j > 0 { ax -= 10 * (*input.add(3 + q - sj) as i64); }
        if j + 1 < ny { ax -= 10 * (*input.add(3 + q + sj) as i64); }
        if k > 0 { ax -= 100 * (*input.add(3 + q - 1) as i64); }
        if k + 1 < nz { ax -= 100 * (*input.add(3 + q + 1) as i64); }
        let b = *input.add(3 + cells + q) as i64;
        *output.add(q) = (10 * b - ax) as f64 / 10.0;
    } } }
    cells as i64
}
