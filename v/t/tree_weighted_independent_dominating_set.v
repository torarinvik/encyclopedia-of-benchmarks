// Uncompiled weighted independent tree domination draft.
fn twid_min(a i64,b i64) i64 { return if a<b { a } else { b } }
fn twid_add(a i64,b i64) i64 { return twid_min(i64(1000000000000),a+b) }
@[export: 'tree_weighted_independent_dominating_set']
pub fn tree_weighted_independent_dominating_set(input &i64,length usize) i64 {
    if length<2 || length>129 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv:=input[0]
        if nv<1 || nv>64 || length!=usize(2*nv) { return -1 }
        n:=int(nv)
        for v in 1 .. n { if input[v]<0 || input[v]>=i64(v) { return -1 } }
        mut selected:=[64]i64{}
        mut covered:=[64]i64{}
        mut waiting:=[64]i64{}
        for v in 0 .. n {
            weight:=input[n+v]
            if weight<0 || weight>1000000 { return -1 }
            selected[v]=weight; covered[v]=i64(1000000000000)
        }
        mut v:=n-1
        for v>0 {
            p:=int(input[v])
            a,b,c:=selected[v],covered[v],waiting[v]
            next:=twid_min(twid_add(covered[p],twid_min(a,b)),twid_add(waiting[p],a))
            selected[p]=twid_add(selected[p],twid_min(b,c))
            waiting[p]=twid_add(waiting[p],b); covered[p]=next
            v--
        }
        return twid_min(selected[0],covered[0])
    }
}
