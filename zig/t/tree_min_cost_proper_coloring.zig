// Uncompiled bounded minimum-cost proper tree coloring draft.
export fn tree_min_cost_proper_coloring(input: [*c]const i64, length: usize) i64 {
    if (input==null or length<2 or length>1090) return -1;
    const nv=input[0]; const kv=input[1];
    if (nv<1 or nv>64 or kv<1 or kv>16) return -1;
    const n: usize=@intCast(nv); const k: usize=@intCast(kv);
    if (length!=n+1+n*k) return -1;
    for (1..n) |v| if (input[1+v]<0 or input[1+v]>=@as(i64,@intCast(v))) { return -1; };
    var dp=[_][16]i64{[_]i64{0} ** 16} ** 64;
    for (0..n) |v| for (0..k) |c| {
        const value=input[n+1+v*k+c];
        if (value<0 or value>1_000_000) return -1;
        dp[v][c]=value;
    };
    if (n>1 and k==1) return -2;
    var child=n;
    while (child>1) {
        child-=1;
        const parent: usize=@intCast(input[1+child]);
        var least: i64=64_000_001; var second: i64=64_000_001; var best_color: usize=0;
        for (0..k) |c| {
            const value=dp[child][c];
            if (value<least) { second=least; least=value; best_color=c; }
            else if (value<second) { second=value; }
        }
        for (0..k) |c| dp[parent][c]+=if (c==best_color) second else least;
    }
    var best=dp[0][0];
    for (1..k) |c| best=@min(best,dp[0][c]);
    return best;
}
