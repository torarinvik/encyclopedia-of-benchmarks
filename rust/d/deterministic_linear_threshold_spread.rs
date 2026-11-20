fn store_i64_le(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn deterministic_linear_threshold_spread(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const N: usize = 8;
    const M: usize = 24;
    if input.is_null() || !(3..=92).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n_raw, m_raw, s_raw) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&n_raw) || !(0..=24).contains(&m_raw) || s_raw < 0 || s_raw > n_raw { return -1; }
    let (n, m, s) = (n_raw as usize, m_raw as usize, s_raw as usize);
    let seed_start = 3;
    let edge_start = seed_start + s;
    let threshold_start = edge_start + 3 * m;
    if length != threshold_start + n { return -1; }
    let mut seed = [false; N];
    let mut edge_seen = [[false; N]; N];
    let mut adjacency = [[0i64; N]; N];
    let mut incoming = [0i64; N];
    let mut accumulated = [0i64; N];
    for &raw in &values[seed_start..edge_start] {
        if raw < 0 || raw as usize >= n || seed[raw as usize] { return -1; }
        seed[raw as usize] = true;
    }
    for e in 0..m {
        let (u, v, w) = (values[edge_start + 3 * e], values[edge_start + 3 * e + 1], values[edge_start + 3 * e + 2]);
        if u < 0 || u as usize >= n || v < 0 || v as usize >= n || u == v || !(0..=16).contains(&w) || edge_seen[u as usize][v as usize] { return -1; }
        edge_seen[u as usize][v as usize] = true;
        adjacency[u as usize][v as usize] = w;
        incoming[v as usize] += w;
        if incoming[v as usize] > 16 { return -1; }
    }
    let mut threshold = [0i64; N];
    let mut round = [-1i64; N];
    for v in 0..n {
        threshold[v] = values[threshold_start + v];
        if !(1..=16).contains(&threshold[v]) { return -1; }
        if seed[v] { round[v] = 0; }
    }
    let bytes = 8 * (n + 2);
    if output.is_null() || capacity < bytes { return -2; }
    let mut current = [0usize; N];
    let mut next = [0usize; N];
    let mut current_len = 0;
    for v in 0..n { if seed[v] { current[current_len] = v; current_len += 1; } }
    let mut wave = 0i64;
    while current_len != 0 {
        let mut next_len = 0;
        for &source in &current[..current_len] {
            for target in 0..n {
                let weight = adjacency[source][target];
                if round[target] >= 0 || weight == 0 { continue; }
                accumulated[target] += weight;
                if accumulated[target] >= threshold[target] {
                    round[target] = wave + 1;
                    next[next_len] = target;
                    next_len += 1;
                }
            }
        }
        std::mem::swap(&mut current, &mut next);
        current_len = next_len;
        if current_len != 0 { wave += 1; }
    }
    let result = unsafe { std::slice::from_raw_parts_mut(output, bytes) };
    store_i64_le(result, 0, n_raw);
    store_i64_le(result, 8, wave);
    for v in 0..n { store_i64_le(result, 8 * (v + 2), round[v]); }
    bytes as i64
}
