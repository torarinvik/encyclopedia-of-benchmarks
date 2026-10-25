/// Clean-room bounded port of TSVC s171; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s171_stride_indexed_accumulate(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    const MAX_STRIDE: usize = 4;
    if input.is_null() || length < 4 || length > 159 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 ||
        values[1] < 1 || values[1] > MAX_STRIDE as i64 { return -1; }
    let n = values[0] as usize;
    let stride = values[1] as usize;
    let a_length = 1 + (n - 1) * stride;
    if length != 2 + a_length + n { return -1; }
    if values[2..].iter().any(|value| !(-8..=8).contains(value)) { return -1; }
    if output.is_null() || capacity < 8 * a_length { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 8 * a_length) };
    for i in 0..a_length {
        out[8 * i..8 * i + 8].copy_from_slice(&values[2 + i].to_le_bytes());
    }
    let b_offset = 2 + a_length;
    for i in 0..n {
        let destination = i * stride;
        let value = values[2 + destination] + values[b_offset + i];
        out[8 * destination..8 * destination + 8].copy_from_slice(&value.to_le_bytes());
    }
    a_length as i64
}
