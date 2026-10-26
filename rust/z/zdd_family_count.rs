#[no_mangle]
pub unsafe extern "C" fn zdd_family_count(input: *const i64, length: usize,
                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 34 { return -1; }
    let src = std::slice::from_raw_parts(input, length);
    let n0 = src[0]; let m0 = src[1];
    if !(1..=6).contains(&n0) || !(0..=32).contains(&m0) || length != m0 as usize + 2 { return -1; }
    let n = n0 as usize; let limit = 1usize << n; let m = m0 as usize;
    let mut ids = [0i64; 64]; let mut next = [0i64; 64];
    let mut vars = [0i64; 63]; let mut lows = [0i64; 63]; let mut highs = [0i64; 63];
    let mut counts = [0i64; 65]; counts[1] = 1;
    let mut seen = [false; 64];
    for i in 0..m {
        let mask = src[2 + i];
        if mask < 0 || mask as usize >= limit || seen[mask as usize] { return -1; }
        seen[mask as usize] = true; ids[mask as usize] = 1;
    }
    let mut nodes = 0usize; let mut current_count = limit;
    for variable in 0..n {
        let next_count = current_count / 2;
        for p in 0..next_count {
            let low = ids[2 * p]; let high = ids[2 * p + 1];
            if high == 0 { next[p] = low; continue; }
            let mut found = nodes; let mut j = nodes;
            while j > 0 {
                j -= 1;
                if vars[j] as usize != variable { break; }
                if lows[j] == low && highs[j] == high { found = j; break; }
            }
            if found == nodes {
                vars[nodes] = variable as i64; lows[nodes] = low; highs[nodes] = high;
                counts[2 + nodes] = counts[low as usize] + counts[high as usize];
                next[p] = (2 + nodes) as i64; nodes += 1;
            } else { next[p] = (2 + found) as i64; }
        }
        ids[..next_count].copy_from_slice(&next[..next_count]); current_count = next_count;
    }
    let bytes = 8 * (3 + 3 * nodes);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    let flat = std::iter::once(ids[0]).chain(std::iter::once(nodes as i64))
        .chain(std::iter::once(counts[ids[0] as usize]))
        .chain((0..nodes).flat_map(|i| [vars[i], lows[i], highs[i]]));
    for (i, value) in flat.enumerate() { dst[i*8..i*8+8].copy_from_slice(&value.to_le_bytes()); }
    bytes as i64
}
