/// Clean-room bounded port of TSVC s4117; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s4117_pair_replicated_gather_map(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 64;
    if input.is_null() || length < 4 || length > 161 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    let c_length = (n + 1) / 2;
    if length != 1 + 2 * n + c_length { return -1; }
    if values[1..].iter().any(|value| !(-2..=2).contains(value)) { return -1; }
    if output.is_null() || capacity < 8 * n { return -2; }
    let b_offset = 1;
    let c_offset = 1 + n;
    let d_offset = c_offset + c_length;
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * n) };
    for i in 0..n {
        let value = values[b_offset + i] + values[c_offset + i / 2] * values[d_offset + i];
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    n as i64
}
