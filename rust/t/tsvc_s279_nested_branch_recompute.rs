const MAX_N: usize = 64;
const MAX_PASSES: usize = 8;
const MAX_INPUT_LENGTH: usize = 2 + 5 * MAX_N;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (byte * 8)) as u8); }
    }
}

/// Clean-room bounded port of TSVC s279; see package README for provenance.
#[no_mangle]
pub unsafe extern "C" fn tsvc_s279_nested_branch_recompute(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let passes_raw = values[1];
    if !(1..=MAX_N as i64).contains(&n_raw) || !(1..=MAX_PASSES as i64).contains(&passes_raw) { return -1; }
    let n = n_raw as usize;
    let passes = passes_raw as usize;
    if length != 2 + 5 * n || values[2..].iter().any(|&value| !(-2..=2).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 24 * n { return -2; }

    let a_start = 2;
    let b_start = a_start + n;
    let c_start = b_start + n;
    let d_start = c_start + n;
    let e_start = d_start + n;
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    a[..n].copy_from_slice(&values[a_start..b_start]);
    b[..n].copy_from_slice(&values[b_start..c_start]);
    c[..n].copy_from_slice(&values[c_start..d_start]);
    for _ in 0..passes {
        for i in 0..n {
            if a[i] > 0 {
                c[i] = -c[i] + values[e_start + i] * values[e_start + i];
            } else {
                b[i] = -b[i] + values[d_start + i] * values[d_start + i];
                if b[i] > a[i] { c[i] += values[d_start + i] * values[e_start + i]; }
            }
            a[i] = b[i] + c[i] * values[d_start + i];
        }
    }
    for i in 0..n {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
        store_i64_le(output, 8 * (2 * n + i), c[i]);
    }
    (3 * n) as i64
}
