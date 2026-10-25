/// Clean-room bounded port of TSVC s162; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s162_guarded_shifted_fma(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 5 || length > 194 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 || values[1] < 0 || values[1] > 1 {
        return -1;
    }
    let n = values[0] as usize;
    if length != 2 + 3 * n { return -1; }
    if values[2..].iter().any(|value| !(-2..=2).contains(value)) { return -1; }
    if output.is_null() || capacity < 8 * n { return -2; }
    let a_offset = 2;
    let b_offset = a_offset + n;
    let c_offset = b_offset + n;
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for i in 0..n {
        out[8 * i..8 * i + 8].copy_from_slice(&values[a_offset + i].to_le_bytes());
    }
    if values[1] > 0 {
        for i in 0..n.saturating_sub(1) {
            let value = values[a_offset + i + 1] + values[b_offset + i] * values[c_offset + i];
            out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
        }
    }
    n as i64
}
