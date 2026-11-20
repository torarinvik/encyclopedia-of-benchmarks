// Uncompiled weighted tree dominating-set draft.
fn twd_add(a i64,b i64) i64 {
    sum:=a+b
    return if sum<i64(1000000000000) { sum } else { i64(1000000000000) }
}
@[export: 'tree_weighted_dominating_set']
pub fn tree_weighted_dominating_set(input &i64,length usize) i64 {
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
            m:=if a<b { a } else { b }
            left:=twd_add(covered[p],m)
            right:=twd_add(waiting[p],a)
            next:=if left<right { left } else { right }
            smallest:=if m<c { m } else { c }
            selected[p]=twd_add(selected[p],smallest)
            waiting[p]=twd_add(waiting[p],b)
            covered[p]=next
            v--
        }
        return if selected[0]<covered[0] { selected[0] } else { covered[0] }
    }
}
