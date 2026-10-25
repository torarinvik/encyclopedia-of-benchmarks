const MAX_N: usize = 16;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 2 + MAX_N + 2 * MAX_CELLS;
const MAX_A0: i64 = 1_000;
const MAX_FACTOR: i64 = 1_000;
const MAX_C0: i64 = 1_000_000;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (byte * 8)) as u8); }
    }
}

/// Clean-room bounded port of TSVC s256; see package README for provenance.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s256_array_expansion(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let a0 = values[1];
    if !(1..=MAX_N as i64).contains(&n_raw) || !(-MAX_A0..=MAX_A0).contains(&a0) { return -1; }
    let n = n_raw as usize;
    let cells = n * n;
    if length != 2 + n + 2 * cells { return -1; }
    let d_start = 2;
    let b_start = d_start + n;
    let c_start = b_start + cells;
    if values[d_start..b_start].iter().any(|&x| !(-MAX_FACTOR..=MAX_FACTOR).contains(&x)) { return -1; }
    if values[b_start..c_start].iter().any(|&x| !(-MAX_FACTOR..=MAX_FACTOR).contains(&x)) ||
       values[c_start..].iter().any(|&x| !(-MAX_C0..=MAX_C0).contains(&x)) { return -1; }

    let output_values = n + cells;
    if output.is_null() || output_capacity < output_values * 8 { return -2; }
    let mut a = [0i64; MAX_N];
    let mut c = [0i64; MAX_CELLS];
    a[0] = a0;
    c[..cells].copy_from_slice(&values[c_start..]);
    for column in 0..n {
        for row in 1..n {
            a[row] = 1 - a[row - 1];
            let cell = row * n + column;
            c[cell] = a[row] + values[b_start + cell] * values[d_start + row];
        }
    }
    for row in 0..n { store_i64_le(output, row * 8, a[row]); }
    for cell in 0..cells { store_i64_le(output, (n + cell) * 8, c[cell]); }
    output_values as i64
}
