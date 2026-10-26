const MAX_N: usize = 12;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 18;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn min_sum_set_cover_greedy(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 1 || m64 > MAX_M as i64
        || length != 2 + m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut masks = [0u64; MAX_M];
    for set in 0..m {
        let raw = *input.add(2 + set);
        if raw <= 0 || raw as u64 >= (1u64 << n) { return -1; }
        masks[set] = raw as u64;
    }
    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut covered = [false; MAX_M];
    let mut used = [false; MAX_N];
    let mut order = [0i64; MAX_N];
    let mut total_time = 0i64;
    for slot in 1..=n {
        let mut chosen = 0usize;
        let mut best_count = -1i32;
        for element in 0..n {
            if used[element] { continue; }
            let mut count = 0i32;
            for set in 0..m {
                if !covered[set] && (masks[set] & (1u64 << element)) != 0 { count += 1; }
            }
            if count > best_count { best_count = count; chosen = element; }
        }
        used[chosen] = true;
        order[slot - 1] = chosen as i64;
        for set in 0..m {
            if !covered[set] && (masks[set] & (1u64 << chosen)) != 0 {
                covered[set] = true;
                total_time += slot as i64;
            }
        }
    }
    store_i64_le(output, 0, total_time);
    for i in 0..n { store_i64_le(output, 8 * (i + 1), order[i]); }
    output_bytes as i64
}
