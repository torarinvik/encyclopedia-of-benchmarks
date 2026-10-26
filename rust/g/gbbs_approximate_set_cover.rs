// Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
#[no_mangle]
pub unsafe extern "C" fn gbbs_approximate_set_cover(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const MAX_INPUT: usize = 10;
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let ns64 = *input;
    if !(1..=8).contains(&ns64) { return -1; }
    let ns = ns64 as usize;
    let ne = ns;
    if length != 1 + ns { return -1; }
    let valid = ((1u16 << ne) - 1) as u64;
    let mut sets = [0u16; 8];
    for s in 0..ns {
        let value = *input.add(1 + s);
        if value < 0 || (value as u64) & !valid != 0 { return -1; }
        sets[s] = value as u16;
        if sets[s] & (1u16 << s) != 0 { return -1; }
    }
    for u in 0..ns { for v in 0..ns {
        if ((sets[u] >> v) & 1) != ((sets[v] >> u) & 1) { return -1; }
    } }
    if output.is_null() || capacity < 16 { return -2; }
    let mut uncovered = valid as u16;
    let mut selected = 0u16;
    let mut bucket = [0usize; 8];
    for s in 0..ns { bucket[s] = sets[s].count_ones() as usize; }
    let mut round = 0usize;
    while uncovered != 0 {
        let mut degree = [0usize; 8];
        let mut top = 0usize;
        for s in 0..ns { top = top.max(bucket[s]); }
        if top == 0 { break; }
        let mut eligible = [false; 8];
        let mut eligible_count = 0usize;
        for s in 0..ns {
            if bucket[s] == top {
                degree[s] = (sets[s] & uncovered).count_ones() as usize;
                bucket[s] = degree[s];
                eligible[s] = degree[s] >= top;
                if eligible[s] { eligible_count += 1; }
            }
        }
        let mut priority = [0usize; 8];
        let mut priority_count = 0usize;
        for r in 0..ns {
            let s = (round + r) % ns;
            if eligible[s] { priority[priority_count] = s; priority_count += 1; }
        }
        let mut wins = [0usize; 8];
        for e in 0..ne {
            let bit = 1u16 << e;
            if uncovered & bit == 0 { continue; }
            for r in 0..priority_count {
                let s = priority[r];
                if sets[s] & bit != 0 { wins[s] += 1; break; }
            }
        }
        let mut round_cover = 0u16;
        for s in 0..ns { if eligible[s] && wins[s] >= top { round_cover |= 1u16 << s; } }
        if round_cover == 0 && eligible_count != 0 { return -1; }
        selected |= round_cover;
        let mut covered = 0u16;
        for s in 0..ns { if round_cover & (1u16 << s) != 0 { covered |= sets[s]; } }
        uncovered &= !covered;
        for s in 0..ns { if round_cover & (1u16 << s) != 0 { bucket[s] = 0; } }
        round += 1;
    }
    for (offset, value) in [selected as i64, uncovered as i64].iter().enumerate() {
        let bits = *value as u64;
        for byte in 0..8 { *output.add(offset * 8 + byte) = (bits >> (8 * byte)) as u8; }
    }
    16
}
