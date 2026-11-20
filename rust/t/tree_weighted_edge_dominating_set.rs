//! Uncompiled minimum-weight tree edge-domination draft.
#[no_mangle]
pub unsafe extern "C" fn tree_weighted_edge_dominating_set(input: *const i64, length: usize) -> i64 {
    const INF: i64 = 1_000_000_000_000;
    if input.is_null() || !(1..=128).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(1..=64).contains(&nv) || length != 2 * nv as usize - 1 { return -1; }
    let n = nv as usize;
    for v in 1..n {
        if values[v] < 0 || values[v] >= v as i64 || !(0..=1_000_000).contains(&values[n + v - 1]) { return -1; }
    }
    let (mut selected, mut closed, mut pending) = ([INF; 64], [0i64; 64], [0i64; 64]);
    for v in (1..n).rev() {
        let p = values[v] as usize;
        let skip = selected[v].min(closed[v]);
        let take = values[n + v - 1] + selected[v].min(pending[v]);
        selected[p] = (selected[p] + skip.min(take)).min(pending[p] + take).min(INF);
        closed[p] = (closed[p] + selected[v]).min(INF);
        pending[p] = (pending[p] + skip).min(INF);
    }
    selected[0].min(closed[0])
}
