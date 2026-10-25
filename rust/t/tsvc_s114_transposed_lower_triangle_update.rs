/// Clean-room port of TSVC s114; see the package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s114_transposed_lower_triangle_update(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 16;
    if input.is_null() || length < 9 || length > 1 + 2 * MAX_N * MAX_N { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(2..=MAX_N as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    let cells = n * n;
    if length != 1 + 2 * cells { return -1; }
    let mut a = [0i64; MAX_N * MAX_N];
    let mut b = [0i64; MAX_N * MAX_N];
    for i in 0..cells {
        a[i] = values[1 + i];
        b[i] = values[1 + cells + i];
        if !(-1_000_000..=1_000_000).contains(&a[i]) ||
            !(-1_000_000..=1_000_000).contains(&b[i]) { return -1; }
    }
    let output_bytes = 8 * cells;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..n {
        for j in 0..i {
            a[i * n + j] = a[j * n + i] + b[i * n + j];
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (i, &value) in a[..cells].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    cells as i64
}
