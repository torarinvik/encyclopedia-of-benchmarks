const MAX_JOBS: usize = 32;
const QUANTUM: i64 = 2;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn round_robin(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    if !(0..=MAX_JOBS as i64).contains(&raw_count) || length != raw_count as usize + 1 { return -1; }
    let count = raw_count as usize;
    let bursts = &values[1..];
    if bursts.iter().any(|&burst| !(0..=4096).contains(&burst)) { return -1; }
    let bytes = (1 + 2 * count) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut remaining = [0i64; MAX_JOBS];
    let mut waiting = [0i64; MAX_JOBS];
    remaining[..count].copy_from_slice(bursts);
    let mut elapsed = 0i64;
    loop {
        let mut done = true;
        for i in 0..count {
            if remaining[i] > 0 {
                done = false;
                if remaining[i] > QUANTUM {
                    elapsed += QUANTUM;
                    remaining[i] -= QUANTUM;
                } else {
                    elapsed += remaining[i];
                    waiting[i] = elapsed - bursts[i];
                    remaining[i] = 0;
                }
            }
        }
        if done { break; }
    }
    let result = std::slice::from_raw_parts_mut(output, bytes);
    put_i64_le(result, 0, raw_count);
    for i in 0..count { put_i64_le(result, 8 * (1 + i), waiting[i]); }
    for i in 0..count { put_i64_le(result, 8 * (1 + count + i), bursts[i] + waiting[i]); }
    bytes as i64
}
