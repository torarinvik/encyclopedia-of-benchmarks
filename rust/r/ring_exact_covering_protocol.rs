const SCALE: i64 = 16;
const MAX_N: usize = 12;
const MAX_STEPS: usize = 64;
const MAX_INPUT: usize = 79;
const MAX_OUTPUT: usize = 208;
fn put(out: &mut [u8; MAX_OUTPUT], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn ring_exact_covering_protocol(input: *const i64, length: usize,
                                                 output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if v[0] < 2 || v[0] > MAX_N as i64 || v[2] < 0 || v[2] > MAX_STEPS as i64 { return -1; }
    let n = v[0] as usize; let steps = v[2] as usize;
    if length != 3 + n + steps { return -1; }
    let circumference = SCALE * n as i64; let visibility = v[1];
    if visibility < 2 * SCALE || visibility > circumference { return -1; }
    let mut position = [0i64; MAX_N];
    for i in 0..n {
        position[i] = v[3 + i];
        if position[i] < 0 || position[i] >= circumference || (i > 0 && position[i - 1] >= position[i]) { return -1; }
    }
    for j in 0..steps { if v[3 + n + j] < 0 || v[3 + n + j] >= n as i64 { return -1; } }
    let mut moved = 0i64;
    for j in 0..steps {
        let i = v[3 + n + j] as usize; let next = (i + 1) % n;
        let gap = (position[next] - position[i] + circumference) % circumference;
        let distance = if gap > visibility { SCALE } else if gap > SCALE { gap - SCALE } else { 0 };
        if distance != 0 { position[i] = (position[i] + distance) % circumference; moved += 1; }
    }
    let words = 2 + 2 * n; let bytes = 8 * words;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT]; put(&mut staged, 0, n as i64); put(&mut staged, 8, moved);
    for i in 0..n { put(&mut staged, 8 * (2 + i), position[i]); }
    for i in 0..n { let gap = (position[(i + 1) % n] - position[i] + circumference) % circumference; put(&mut staged, 8 * (2 + n + i), gap); }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes); }
    bytes as i64
}
