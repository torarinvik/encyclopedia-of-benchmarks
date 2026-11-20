//! Uncompiled weighted total-domination tree draft.
const INF: i64 = 1_000_000_000_000;
fn add(a:i64,b:i64)->i64 { (a+b).min(INF) }
#[no_mangle]
pub unsafe extern "C" fn tree_weighted_total_dominating_set(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(2..=129).contains(&length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,length) };
    let nv=values[0];
    if !(1..=64).contains(&nv) || length!=2*nv as usize { return -1; }
    let n=nv as usize;
    for v in 1..n { if values[v]<0 || values[v]>=v as i64 { return -1; } }
    let (mut weights,mut none,mut some)=([0i64;64],[[0i64;2];64],[[INF;2];64]);
    for v in 0..n {
        let w=values[n+v];
        if !(0..=1_000_000).contains(&w) { return -1; }
        weights[v]=w;
    }
    let mut root=INF;
    for v in (0..n).rev() {
        let mut dp=[[0i64;2];2];
        for chosen in 0..2 {
            let own=if chosen==1 { weights[v] } else { 0 };
            dp[chosen][0]=add(own,some[v][chosen]);
            dp[chosen][1]=add(own,none[v][chosen].min(some[v][chosen]));
        }
        if v==0 { root=dp[0][0].min(dp[1][0]); break; }
        let p=values[v] as usize;
        for chosen in 0..2 {
            let (absent,present)=(dp[0][chosen],dp[1][chosen]);
            let next=add(some[p][chosen],absent.min(present)).min(add(none[p][chosen],present));
            none[p][chosen]=add(none[p][chosen],absent);
            some[p][chosen]=next;
        }
    }
    if root==INF { -2 } else { root }
}
