//! Uncompiled weighted tree dominating-set draft.
const INF: i64 = 1_000_000_000_000;
fn plus(a: i64, b: i64) -> i64 { (a+b).min(INF) }

#[no_mangle]
pub unsafe extern "C" fn tree_weighted_dominating_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=129).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(1..=64).contains(&nv) || length != 2*nv as usize { return -1; }
    let n = nv as usize;
    for v in 1..n { if values[v] < 0 || values[v] >= v as i64 { return -1; } }
    let (mut selected, mut covered, mut waiting) = ([0i64;64], [INF;64], [0i64;64]);
    for v in 0..n {
        let w=values[n+v];
        if !(0..=1_000_000).contains(&w) { return -1; }
        selected[v]=w;
    }
    for v in (1..n).rev() {
        let p=values[v] as usize;
        let (chosen, dominated, open)=(selected[v],covered[v],waiting[v]);
        let next_covered=plus(covered[p],chosen.min(dominated)).min(plus(waiting[p],chosen));
        selected[p]=plus(selected[p],chosen.min(dominated).min(open));
        waiting[p]=plus(waiting[p],dominated);
        covered[p]=next_covered;
    }
    selected[0].min(covered[0])
}
