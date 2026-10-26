const MAX_N: usize = 16;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 34;
const MAX_OUTPUT: usize = 136;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

fn bit_count(mut value: u64) -> usize {
    let mut count = 0;
    while value != 0 { value &= value - 1; count += 1; }
    count
}

#[no_mangle]
pub unsafe extern "C" fn weighted_greedy_set_cover(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 1 || m64 > MAX_M as i64 ||
        length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let full = (1u64 << n) - 1;
    let mut weights = [0i64; MAX_M];
    let mut masks = [0u64; MAX_M];
    let mut union = 0u64;
    for set in 0..m {
        weights[set] = *input.add(2 + set);
        let value = *input.add(2 + m + set);
        if weights[set] < 0 || weights[set] > 10000 || value < 0 ||
            ((value as u64) & !full) != 0 { return -1; }
        masks[set] = value as u64;
        union |= masks[set];
    }
    if union != full { return -1; }

    let mut covered = 0u64;
    let mut selected = [0usize; MAX_M];
    let mut selected_count = 0usize;
    while covered != full {
        let mut best = None;
        let mut best_gain = 0usize;
        for set in 0..m {
            let gain = bit_count(masks[set] & !covered);
            if gain == 0 { continue; }
            let should_replace = match best {
                None => true,
                Some(previous) => weights[set] * best_gain as i64 <
                    weights[previous] * gain as i64,
            };
            if should_replace { best = Some(set); best_gain = gain; }
        }
        let chosen = match best { Some(index) => index, None => return -1 };
        selected[selected_count] = chosen;
        selected_count += 1;
        covered |= masks[chosen];
    }
    let output_bytes = 8 * (selected_count + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put64(staged.as_mut_ptr(), 0, selected_count as i64);
    for index in 0..selected_count { put64(staged.as_mut_ptr(), 8 * (index + 1), selected[index] as i64); }
    for index in 0..output_bytes { *output.add(index) = staged[index]; }
    output_bytes as i64
}
