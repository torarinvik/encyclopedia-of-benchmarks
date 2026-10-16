fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn gauss_seidel_method(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + n * n + n { return -1; }
    let rhs = 1 + n * n;
    if values[1..].iter().any(|&v| !(-1_000_000_000..=1_000_000_000).contains(&v)) { return -1; }
    for row in 0..n {
        let diagonal = values[1 + row * n + row];
        if diagonal <= 0 { return -1; }
        let mut off_sum = 0_i64;
        for col in 0..n {
            let value = values[1 + row * n + col];
            if value != values[1 + col * n + row] { return -1; }
            if row != col { off_sum += value.abs(); }
        }
        if diagonal <= off_sum { return -1; }
    }
    if output.is_null() || capacity < n * 8 { return -2; }
    let mut a = [0.0_f64; 64];
    let mut b = [0.0_f64; 8];
    let mut x = [0.0_f64; 8];
    let mut old = [0.0_f64; 8];
    for i in 0..n * n { a[i] = values[i + 1] as f64 / 1_000_000.0; }
    for i in 0..n { b[i] = values[rhs + i] as f64 / 1_000_000.0; }
    for _ in 0..1000 {
        old[..n].copy_from_slice(&x[..n]);
        for i in 0..n {
            let mut before = 0.0;
            let mut after = 0.0;
            for j in 0..i { before += a[i * n + j] * x[j]; }
            for j in i + 1..n { after += a[i * n + j] * old[j]; }
            x[i] = (b[i] - before - after) / a[i * n + i];
        }
        if (0..n).all(|i| (x[i] - old[i]).abs() < 1.0e-10) { break; }
    }
    let bytes = std::slice::from_raw_parts_mut(output, n * 8);
    for i in 0..n { put_f64_le(bytes, i * 8, (x[i] * 1.0e10).round() / 1.0e10); }
    (n * 8) as i64
}
