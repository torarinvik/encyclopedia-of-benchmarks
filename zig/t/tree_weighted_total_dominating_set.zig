// Uncompiled weighted total-domination tree draft.
const inf: i64=1_000_000_000_000;
fn add(a:i64,b:i64) i64 { return @min(inf,a+b); }
export fn tree_weighted_total_dominating_set(input:[*c]const i64,length:usize) i64 {
    if (input==null or length<2 or length>129) return -1;
    const nv=input[0];
    if (nv<1 or nv>64 or length!=@as(usize,@intCast(2*nv))) return -1;
    const n:usize=@intCast(nv);
    for (1..n) |v| if (input[v]<0 or input[v]>=@as(i64,@intCast(v))) { return -1; };
    var weights=[_]i64{0} ** 64;
    var none=[_][2]i64{[_]i64{0} ** 2} ** 64;
    var some=[_][2]i64{[_]i64{inf} ** 2} ** 64;
    for (0..n) |v| {
        weights[v]=input[n+v];
        if (weights[v]<0 or weights[v]>1_000_000) return -1;
    }
    var root:i64=inf;
    var v=n;
    while (v>0) {
        v-=1;
        var dp=[_][2]i64{[_]i64{0} ** 2} ** 2;
        for (0..2) |chosen| {
            const own=if (chosen==1) weights[v] else 0;
            dp[chosen][0]=add(own,some[v][chosen]);
            dp[chosen][1]=add(own,@min(none[v][chosen],some[v][chosen]));
        }
        if (v==0) { root=@min(dp[0][0],dp[1][0]); break; }
        const p:usize=@intCast(input[v]);
        for (0..2) |chosen| {
            const a=dp[0][chosen]; const b=dp[1][chosen];
            const next=@min(add(some[p][chosen],@min(a,b)),add(none[p][chosen],b));
            none[p][chosen]=add(none[p][chosen],a);
            some[p][chosen]=next;
        }
    }
    return if (root==inf) -2 else root;
}
