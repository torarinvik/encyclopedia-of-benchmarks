//! Uncompiled minimum tree path-partition draft.
#[no_mangle]
pub unsafe extern "C" fn tree_minimum_path_partition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=65).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(1..=64).contains(&nv) || length != nv as usize { return -1; }
    let n = nv as usize;
    for v in 1..n { if values[v] < 0 || values[v] >= v as i64 { return -1; } }
    let (mut base, mut first, mut second) = ([0i64;64], [0i64;64], [0i64;64]);
    for v in (1..n).rev() {
        let p = values[v] as usize;
        let best = base[v] + first[v] + second[v];
        let gain = 1 + base[v] + first[v] - best;
        base[p] += best;
        if gain > first[p] { second[p] = first[p]; first[p] = gain; }
        else if gain > second[p] { second[p] = gain; }
    }
    nv - base[0] - first[0] - second[0]
}
