const MAX_JOBS: usize = 32;
const SENTINEL: i64 = 999_999_999;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn shortest_job_first(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    if !(0..=MAX_JOBS as i64).contains(&raw_count) || length != 1 + 2 * raw_count as usize { return -1; }
    let count = raw_count as usize;
    let arrivals = &values[1..1 + count];
    let bursts = &values[1 + count..];
    if arrivals.iter().any(|&arrival| !(0..=64).contains(&arrival))
        || bursts.iter().any(|&burst| !(1..=128).contains(&burst) || burst >= SENTINEL) { return -1; }
    let bytes = (1 + 2 * count) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut remaining = [0i64; MAX_JOBS];
    let mut waiting = [0i64; MAX_JOBS];
    remaining[..count].copy_from_slice(bursts);
    let mut complete = 0;
    let mut time = 0i64;
    let mut minimum = SENTINEL;
    let mut short_index = 0usize;
    let mut check = false;
    while complete != count {
        for j in 0..count {
            if arrivals[j] <= time && remaining[j] > 0 && remaining[j] < minimum {
                minimum = remaining[j];
                short_index = j;
                check = true;
            }
        }
        if !check { time += 1; continue; }
        remaining[short_index] -= 1;
        minimum = remaining[short_index];
        if minimum == 0 { minimum = SENTINEL; }
        if remaining[short_index] == 0 {
            complete += 1;
            check = false;
            let wait = time + 1 - arrivals[short_index] - bursts[short_index];
            waiting[short_index] = wait.max(0);
        }
        time += 1;
    }
    let result = std::slice::from_raw_parts_mut(output, bytes);
    put_i64_le(result, 0, raw_count);
    for i in 0..count { put_i64_le(result, 8 * (1 + i), waiting[i]); }
    for i in 0..count { put_i64_le(result, 8 * (1 + count + i), bursts[i] + waiting[i]); }
    bytes as i64
}
