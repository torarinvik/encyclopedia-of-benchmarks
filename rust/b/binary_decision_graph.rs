#[no_mangle]
pub unsafe extern "C" fn binary_decision_graph(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 65 { return -1; }
    let src = std::slice::from_raw_parts(input, length);
    let nv = src[0];
    if !(1..=6).contains(&nv) || length != 1 + (1usize << nv) { return -1; }
    let n = nv as usize;
    let count = 1usize << n;
    let mut ids = [0i64; 64];
    let mut next = [0i64; 64];
    let mut vars = [0i64; 63];
    let mut lows = [0i64; 63];
    let mut highs = [0i64; 63];
    for i in 0..count {
        if src[i + 1] != 0 && src[i + 1] != 1 { return -1; }
        ids[i] = src[i + 1];
    }
    let mut nodes = 0usize;
    let mut current_count = count;
    for step in 0..n {
        let var = n - 1 - step;
        let next_count = current_count / 2;
        for p in 0..next_count {
            let lo = ids[2 * p];
            let hi = ids[2 * p + 1];
            if lo == hi { next[p] = lo; continue; }
            let mut found = nodes;
            let mut j = nodes;
            while j > 0 {
                j -= 1;
                if vars[j] as usize != var { break; }
                if lows[j] == lo && highs[j] == hi { found = j; break; }
            }
            if found == nodes {
                vars[nodes] = var as i64; lows[nodes] = lo; highs[nodes] = hi;
                next[p] = (2 + nodes) as i64; nodes += 1;
            } else { next[p] = (2 + found) as i64; }
        }
        ids[..next_count].copy_from_slice(&next[..next_count]);
        current_count = next_count;
    }
    let bytes = 8 * (2 + 3 * nodes);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    let values_iter = std::iter::once(ids[0]).chain(std::iter::once(nodes as i64))
        .chain((0..nodes).flat_map(|i| [vars[i], lows[i], highs[i]]));
    for (i, value) in values_iter.enumerate() {
        dst[i * 8..i * 8 + 8].copy_from_slice(&value.to_le_bytes());
    }
    bytes as i64
}
