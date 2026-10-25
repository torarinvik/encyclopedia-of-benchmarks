/// Clean-room bounded port of TSVC s4114; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s4114_reverse_index_gather_fma(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 5 || length > 257 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }
    let ip_offset = 1;
    let b_offset = 1 + n;
    let c_offset = 1 + 2 * n;
    let d_offset = 1 + 3 * n;
    for i in 0..n {
        if values[ip_offset + i] < 0 || values[ip_offset + i] >= n as i64 { return -1; }
        if !(-2..=2).contains(&values[b_offset + i]) ||
            !(-2..=2).contains(&values[c_offset + i]) ||
            !(-2..=2).contains(&values[d_offset + i]) { return -1; }
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for i in 0..n {
        let gathered = n - 1 - values[ip_offset + i] as usize;
        let value = values[b_offset + i] + values[c_offset + gathered] * values[d_offset + i];
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
