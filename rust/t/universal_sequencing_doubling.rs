const N: usize = 12;
const MAX_WEIGHT: usize = 32;
const MAX_LEVELS: usize = 6;
const MAX_INPUT: usize = 25;
const MAX_OUTPUT: usize = 104;

fn put(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn universal_sequencing_doubling(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n0 = *values;
    if !(1..=N as i64).contains(&n0) || length != 1 + 2 * n0 as usize { return -1; }
    let n = n0 as usize;
    let mut processing = [0i64; N];
    let mut weight = [0usize; N];
    let mut total_weight = 0usize;
    for job in 0..n {
        let p = *values.add(1 + 2 * job);
        let w = *values.add(2 + 2 * job);
        if !(1..=255).contains(&p) || !(1..=MAX_WEIGHT as i64).contains(&w) { return -1; }
        processing[job] = p;
        weight[job] = w as usize;
        total_weight += w as usize;
    }
    if total_weight > MAX_WEIGHT || total_weight & (total_weight - 1) != 0 { return -1; }
    let mut level_sets = [0u16; MAX_LEVELS];
    let mut levels = 0usize;
    let mut bound = 1usize;
    while bound <= total_weight {
        let mut best = [0i64; MAX_WEIGHT + 1];
        let mut masks = [0u16; MAX_WEIGHT + 1];
        let mut reachable = [false; MAX_WEIGHT + 1];
        reachable[0] = true;
        for job in 0..n {
            for used in (weight[job]..=bound).rev() {
                if !reachable[used - weight[job]] { continue; }
                let candidate = best[used - weight[job]] + processing[job];
                let candidate_mask = masks[used - weight[job]] | (1u16 << job);
                if !reachable[used] || candidate > best[used] ||
                    (candidate == best[used] && candidate_mask < masks[used]) {
                    reachable[used] = true;
                    best[used] = candidate;
                    masks[used] = candidate_mask;
                }
            }
        }
        let mut maximum = -1i64;
        let mut selected = 0u16;
        for used in 0..=bound {
            if reachable[used] && (best[used] > maximum ||
                (best[used] == maximum && masks[used] < selected)) {
                maximum = best[used];
                selected = masks[used];
            }
        }
        level_sets[levels] = selected;
        levels += 1;
        bound *= 2;
    }
    let mut rank = [-1i32; N];
    for job in 0..n {
        for level in 0..levels {
            if level_sets[level] & (1u16 << job) != 0 { rank[job] = level as i32; break; }
        }
        if rank[job] < 0 { return -1; }
    }
    let mut words = [0i64; N + 1];
    words[0] = n as i64;
    let mut count = 1usize;
    for level in (0..levels).rev() {
        for job in 0..n {
            if rank[job] == level as i32 { words[count] = job as i64; count += 1; }
        }
    }
    let bytes = 8 * count;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for i in 0..count { put(&mut staged, 8 * i, words[i]); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
