// Clean-room implementation of TSVC s293; see package rights note.
const MAX_N: i64 = 32;
const MAX_INPUT_LENGTH: usize = 33;

fn store_i64_le(out: *mut u8, pos: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { unsafe { out.add(pos + b).write((bits >> (8*b)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s293_first_element_broadcast(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_N || length != 1 + values[0] as usize { return -1; }
    let n = values[0] as usize;
    if values[1..].iter().any(|v| *v < -8 || *v > 8) { return -1; }
    let bytes = 8*n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0_i64; MAX_N as usize];
    for i in 0..n { staged[i] = values[1]; }
    for i in 0..n { store_i64_le(output, 8*i, staged[i]); }
    bytes as i64
}
