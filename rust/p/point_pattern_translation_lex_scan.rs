const MAX_PATTERN: usize = 6;
const MAX_TARGET: usize = 8;
const MAX_COORD: i64 = 16;

fn point_less(ax: i64, ay: i64, bx: i64, by: i64) -> bool {
    ax < bx || (ax == bx && ay < by)
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn point_pattern_translation_lex_scan(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 31 { return -1; }
    let pattern_raw = *input;
    let target_raw = *input.add(1);
    if pattern_raw < 1 || pattern_raw > MAX_PATTERN as i64 || target_raw < 1 ||
            target_raw > MAX_TARGET as i64 || pattern_raw > target_raw { return -1; }
    let pattern_count = pattern_raw as usize;
    let target_count = target_raw as usize;
    if length != 2 + 2 * (pattern_count + target_count) { return -1; }
    let mut px = [0i64; MAX_PATTERN];
    let mut py = [0i64; MAX_PATTERN];
    let mut tx = [0i64; MAX_TARGET];
    let mut ty = [0i64; MAX_TARGET];
    let mut cursor = 2;
    for i in 0..pattern_count {
        px[i] = *input.add(cursor); py[i] = *input.add(cursor + 1); cursor += 2;
        if px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD { return -1; }
        if i > 0 && !point_less(px[i - 1], py[i - 1], px[i], py[i]) { return -1; }
    }
    for i in 0..target_count {
        tx[i] = *input.add(cursor); ty[i] = *input.add(cursor + 1); cursor += 2;
        if tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD { return -1; }
        if i > 0 && !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i]) { return -1; }
    }
    if output.is_null() || capacity < 24 { return -2; }

    let mut found = 0i64;
    let mut best_x = 0i64;
    let mut best_y = 0i64;
    for anchor in 0..target_count {
        let dx = tx[anchor] - px[0];
        let dy = ty[anchor] - py[0];
        let mut target_index = anchor + 1;
        let mut matches = true;
        for pattern_index in 1..pattern_count {
            let wanted_x = px[pattern_index] + dx;
            let wanted_y = py[pattern_index] + dy;
            while target_index < target_count && point_less(tx[target_index], ty[target_index], wanted_x, wanted_y) { target_index += 1; }
            if target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y {
                matches = false;
                break;
            }
            target_index += 1;
        }
        if matches { found = 1; best_x = dx; best_y = dy; break; }
    }
    let mut staged = [0u8; 24];
    store_i64_le(staged.as_mut_ptr(), 0, found);
    store_i64_le(staged.as_mut_ptr(), 8, best_x);
    store_i64_le(staged.as_mut_ptr(), 16, best_y);
    for byte in 0..24 { *output.add(byte) = staged[byte]; }
    24
}
