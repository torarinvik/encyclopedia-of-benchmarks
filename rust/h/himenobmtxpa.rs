#[no_mangle]
pub unsafe extern "C" fn himenobmtxpa(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let mut dims = [0usize; 4];
    for q in 0..4 {
        let value = unsafe { *input.add(q) };
        if !value.is_finite() || value.fract() != 0.0 { return -1; }
        if q < 3 {
            if !(2.0..=6.0).contains(&value) { return -1; }
        } else if !(1.0..=4.0).contains(&value) { return -1; }
        dims[q] = value as usize;
    }
    let (nx, ny, nz, iterations) = (dims[0], dims[1], dims[2], dims[3]);
    if output.is_null() || capacity < 1 { return -2; }

    let mut p = [0.0_f32; 216];
    let mut work = [0.0_f32; 216];
    let a3 = 1.0_f32 / 6.0_f32;
    let omega = 0.8_f32;
    let denominator = ((nx - 1) * (nx - 1)) as f32;
    for i in 0..nx {
        for j in 0..ny {
            for k in 0..nz {
                let q = i * ny * nz + j * nz + k;
                p[q] = (i * i) as f32 / denominator;
            }
        }
    }
    let mut gosa = 0.0_f32;
    for _ in 0..iterations {
        gosa = 0.0;
        for i in 1..(nx - 1) {
            for j in 1..(ny - 1) {
                for k in 1..(nz - 1) {
                    let q = i * ny * nz + j * nz + k;
                    let mut s0 = p[q + ny * nz] + p[q + nz] + p[q + 1];
                    s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1];
                    let ss = s0 * a3 - p[q];
                    gosa = gosa + ss * ss;
                    work[q] = p[q] + omega * ss;
                }
            }
        }
        for i in 1..(nx - 1) {
            for j in 1..(ny - 1) {
                for k in 1..(nz - 1) {
                    let q = i * ny * nz + j * nz + k;
                    p[q] = work[q];
                }
            }
        }
    }
    unsafe { *output = f64::from(gosa); }
    1
}
