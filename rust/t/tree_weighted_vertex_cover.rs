//! Uncompiled weighted tree vertex-cover draft.
#[no_mangle]
pub unsafe extern "C" fn tree_weighted_vertex_cover(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=129).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(1..=64).contains(&nv) || length != 2*nv as usize { return -1; }
    let n = nv as usize;
    for v in 1..n { if values[v] < 0 || values[v] >= v as i64 { return -1; } }
    let (mut included, mut excluded) = ([0i64; 64], [0i64; 64]);
    for v in 0..n {
        let weight = values[n+v];
        if !(0..=1_000_000).contains(&weight) { return -1; }
        included[v] = weight;
    }
    for v in (1..n).rev() {
        let p = values[v] as usize;
        let child_included = included[v];
        let child_excluded = excluded[v];
        included[p] += child_included.min(child_excluded);
        excluded[p] += child_included;
    }
    included[0].min(excluded[0])
}
