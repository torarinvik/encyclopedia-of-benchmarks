#[no_mangle]
pub unsafe extern "C" fn pfr_local_forward_decision(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let angle = *input;
    let draw = *input.add(1);
    if angle < 0 || angle > 180_000_000 || draw < 0 || draw >= 1_000_000 { return -1; }
    let forward: i64 = if angle >= 134_000_000 || 180 * draw < angle { 1 } else { 0 };
    if output.is_null() || capacity < 8 { return -2; }
    let bits = forward as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
    8
}
