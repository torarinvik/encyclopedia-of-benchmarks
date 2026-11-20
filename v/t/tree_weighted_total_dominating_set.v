// Uncompiled weighted total-domination tree draft.
fn twt_min(a i64,b i64) i64 { return if a<b { a } else { b } }
fn twt_add(a i64,b i64) i64 { return twt_min(i64(1000000000000),a+b) }
@[export: 'tree_weighted_total_dominating_set']
pub fn tree_weighted_total_dominating_set(input &i64,length usize) i64 {
    if length<2 || length>129 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv:=input[0]
        if nv<1 || nv>64 || length!=usize(2*nv) { return -1 }
        n:=int(nv)
        for v in 1 .. n { if input[v]<0 || input[v]>=i64(v) { return -1 } }
        inf:=i64(1000000000000)
        mut weights:=[64]i64{}
        mut none:=[128]i64{}
        mut some:=[128]i64{}
        for v in 0 .. n {
            weights[v]=input[n+v]
            if weights[v]<0 || weights[v]>1000000 { return -1 }
            some[2*v]=inf; some[2*v+1]=inf
        }
        mut root:=inf
        mut v:=n-1
        for v>=0 {
            mut dp:=[4]i64{}
            for chosen in 0 .. 2 {
                own:=if chosen==1 { weights[v] } else { i64(0) }
                dp[2*chosen]=twt_add(own,some[2*v+chosen])
                dp[2*chosen+1]=twt_add(own,twt_min(none[2*v+chosen],some[2*v+chosen]))
            }
            if v==0 { root=twt_min(dp[0],dp[2]); break }
            p:=int(input[v])
            for chosen in 0 .. 2 {
                a,b:=dp[chosen],dp[2+chosen]
                index:=2*p+chosen
                next:=twt_min(twt_add(some[index],twt_min(a,b)),twt_add(none[index],b))
                none[index]=twt_add(none[index],a); some[index]=next
            }
            v--
        }
        return if root==inf { -2 } else { root }
    }
}
