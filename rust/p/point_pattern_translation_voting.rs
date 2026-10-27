const MAX_PATTERN: usize = 6;
const MAX_TARGET: usize = 8;
const MAX_COORD: i64 = 16;
const MAX_PAIRS: usize = 48;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn point_pattern_translation_voting(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 31 { return -1; }
    let pattern_raw = *input;
    let target_raw = *input.add(1);
    if pattern_raw < 1 || pattern_raw > MAX_PATTERN as i64 || target_raw < 1 || target_raw > MAX_TARGET as i64 { return -1; }
    let pattern_count = pattern_raw as usize;
    let target_count = target_raw as usize;
    if length != 2 + 2 * (pattern_count + target_count) { return -1; }
    let mut px = [0i64; MAX_PATTERN];
    let mut py = [0i64; MAX_PATTERN];
    let mut tx = [0i64; MAX_TARGET];
    let mut ty = [0i64; MAX_TARGET];
    let mut cursor = 2usize;
    for i in 0..pattern_count {
        px[i] = *input.add(cursor); py[i] = *input.add(cursor + 1); cursor += 2;
        if px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD { return -1; }
        for j in 0..i { if px[i] == px[j] && py[i] == py[j] { return -1; } }
    }
    for i in 0..target_count {
        tx[i] = *input.add(cursor); ty[i] = *input.add(cursor + 1); cursor += 2;
        if tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD { return -1; }
        for j in 0..i { if tx[i] == tx[j] && ty[i] == ty[j] { return -1; } }
    }
    if output.is_null() { return -2; }
    let mut dx = [0i64; MAX_PAIRS];
    let mut dy = [0i64; MAX_PAIRS];
    let mut pair_count = 0usize;
    for p in 0..pattern_count { for t in 0..target_count {
        dx[pair_count] = tx[t] - px[p]; dy[pair_count] = ty[t] - py[p]; pair_count += 1;
    }}
    for i in 1..pair_count {
        let key_x = dx[i]; let key_y = dy[i];
        let mut j = i;
        while j > 0 && (dx[j - 1] > key_x || dx[j - 1] == key_x && dy[j - 1] > key_y) {
            dx[j] = dx[j - 1]; dy[j] = dy[j - 1]; j -= 1;
        }
        dx[j] = key_x; dy[j] = key_y;
    }
    let mut best_count = 0usize;
    let mut best_x = dx[0]; let mut best_y = dy[0];
    let mut i = 0usize;
    while i < pair_count {
        let mut end = i + 1;
        while end < pair_count && dx[end] == dx[i] && dy[end] == dy[i] { end += 1; }
        if end - i > best_count { best_count = end - i; best_x = dx[i]; best_y = dy[i]; }
        i = end;
    }
    if capacity < 24 { return -2; }
    let mut staged = [0u8; 24];
    store_i64_le(staged.as_mut_ptr(), 0, best_count as i64);
    store_i64_le(staged.as_mut_ptr(), 8, best_x);
    store_i64_le(staged.as_mut_ptr(), 16, best_y);
    for byte in 0..24 { *output.add(byte) = staged[byte]; }
    24
}
