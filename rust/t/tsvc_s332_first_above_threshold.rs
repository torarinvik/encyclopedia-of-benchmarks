/// Clean-room bounded port of TSVC s332; see package README for provenance.
#[no_mangle]
pub extern "C" fn tsvc_s332_first_above_threshold(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 256;
    if input.is_null() || length < 3 || length > 258 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 ||
        values[1] < -1000000 || values[1] > 1000000 { return -1; }
    let n = values[0] as usize;
    let threshold = values[1];
    if length != 2 + n { return -1; }
    let mut items = [0i64; MAX_N];
    for i in 0..n {
        items[i] = values[2 + i];
        if items[i] < -1000000 || items[i] > 1000000 { return -1; }
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut index = -2i64;
    let mut value = -1i64;
    for i in 0..n {
        if items[i] > threshold {
            index = i as i64;
            value = items[i];
            break;
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, 16) };
    out[0..8].copy_from_slice(&index.to_le_bytes());
    out[8..16].copy_from_slice(&value.to_le_bytes());
    2
}
