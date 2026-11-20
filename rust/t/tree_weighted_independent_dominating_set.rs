//! Uncompiled weighted independent tree domination draft.
const INF:i64=1_000_000_000_000;
fn add(a:i64,b:i64)->i64 { (a+b).min(INF) }
#[no_mangle]
pub unsafe extern "C" fn tree_weighted_independent_dominating_set(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(2..=129).contains(&length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,length) };
    let nv=values[0];
    if !(1..=64).contains(&nv) || length!=2*nv as usize { return -1; }
    let n=nv as usize;
    for v in 1..n { if values[v]<0 || values[v]>=v as i64 { return -1; } }
    let (mut selected,mut covered,mut waiting)=([0i64;64],[INF;64],[0i64;64]);
    for v in 0..n {
        let w=values[n+v];
        if !(0..=1_000_000).contains(&w) { return -1; }
        selected[v]=w;
    }
    for v in (1..n).rev() {
        let p=values[v] as usize;
        let (a,b,c)=(selected[v],covered[v],waiting[v]);
        let next=add(covered[p],a.min(b)).min(add(waiting[p],a));
        selected[p]=add(selected[p],b.min(c));
        waiting[p]=add(waiting[p],b);
        covered[p]=next;
    }
    selected[0].min(covered[0])
}
