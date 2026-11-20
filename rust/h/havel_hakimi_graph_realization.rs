const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 10;

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn construct(degrees: &[i64]) -> Option<([i64; 58], usize)> {
    let n = degrees.len();
    let mut residual = [0_i64; MAX_N];
    let mut active = [false; MAX_N];
    for i in 0..n { residual[i] = degrees[i]; active[i] = true; }
    let mut left = [0_i64; MAX_EDGES];
    let mut right = [0_i64; MAX_EDGES];
    let mut edge_count = 0;
    loop {
        let mut hub: Option<usize> = None;
        for v in 0..n {
            if active[v] && residual[v] > 0 && hub.map_or(true, |h| residual[v] > residual[h] || (residual[v] == residual[h] && v < h)) { hub = Some(v); }
        }
        let Some(h) = hub else { break; };
        let d = residual[h] as usize; residual[h] = 0; active[h] = false;
        let mut candidates = [0_usize; MAX_N];
        let mut count = 0;
        for v in 0..n { if active[v] { candidates[count] = v; count += 1; } }
        candidates[..count].sort_by_key(|&v| (-residual[v], v));
        if d > count { return None; }
        for &v in &candidates[..d] {
            if residual[v] == 0 { return None; }
            residual[v] -= 1;
            left[edge_count] = h.min(v) as i64; right[edge_count] = h.max(v) as i64; edge_count += 1;
        }
    }
    let mut words = [0_i64; 58];
    words[0] = 1; words[1] = edge_count as i64;
    for i in 0..edge_count { words[2 + 2 * i] = left[i]; words[3 + 2 * i] = right[i]; }
    Some((words, 2 + 2 * edge_count))
}

#[no_mangle]
pub unsafe extern "C" fn havel_hakimi_graph_realization(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if n64 < 0 || n64 > MAX_N as i64 { return -1; }
    let n = n64 as usize;
    if length != n + 1 || values[1..].iter().any(|&d| d < 0 || d >= n64 as i64) { return -1; }
    let (words, word_count) = match construct(&values[1..]) {
        Some(result) => result,
        None => { let mut empty = [0_i64; 58]; empty[0] = 0; (empty, 1) }
    };
    if output.is_null() || capacity < word_count * 8 { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, word_count * 8);
    for i in 0..word_count { store_i64(bytes, i * 8, words[i]); }
    (word_count * 8) as i64
}
