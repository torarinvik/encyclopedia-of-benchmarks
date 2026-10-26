#[derive(Clone, Copy)]
struct Edge { u: usize, v: usize, weight: i64, used: bool }

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn approximate_matching_greedy(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 98 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0]; let m0 = values[1];
    if !(1..=12).contains(&n0) || !(0..=32).contains(&m0) || length != 2 + 3 * m0 as usize { return -1; }
    let m = m0 as usize;
    let mut seen = [[false; 12]; 12]; let mut matched = [false; 12];
    let mut edges = [Edge { u: 0, v: 0, weight: 0, used: false }; 32];
    for i in 0..m {
        let u0 = values[2 + 3*i]; let v0 = values[3 + 3*i]; let weight = values[4 + 3*i];
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || !(1..=100).contains(&weight) { return -1; }
        let u = u0 as usize; let v = v0 as usize; let (lo, hi) = if u < v {(u,v)} else {(v,u)};
        if seen[lo][hi] { return -1; }
        seen[lo][hi] = true; edges[i] = Edge { u, v, weight, used: false };
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut total = 0i64; let mut selected = 0u64;
    for _ in 0..m {
        let mut best = m;
        for i in 0..m { if !edges[i].used && (best == m || edges[i].weight > edges[best].weight) { best = i; } }
        edges[best].used = true; let edge = edges[best];
        if !matched[edge.u] && !matched[edge.v] {
            matched[edge.u] = true; matched[edge.v] = true;
            selected |= 1u64 << best; total += edge.weight;
        }
    }
    let dst = std::slice::from_raw_parts_mut(output, 16);
    put_i64(dst, 0, total); put_i64(dst, 1, selected as i64); 16
}
