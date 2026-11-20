// Uncompiled weighted tree vertex-cover draft.
export fn tree_weighted_vertex_cover(input: [*c]const i64, length: usize) i64 {
    if (input==null or length<2 or length>129) return -1;
    const nv=input[0];
    if (nv<1 or nv>64 or length!=@as(usize,@intCast(2*nv))) return -1;
    const n: usize=@intCast(nv);
    for (1..n) |v| if (input[v]<0 or input[v]>=@as(i64,@intCast(v))) { return -1; };
    var included=[_]i64{0} ** 64;
    var excluded=[_]i64{0} ** 64;
    for (0..n) |v| {
        const weight=input[n+v];
        if (weight<0 or weight>1_000_000) return -1;
        included[v]=weight;
    }
    var v=n;
    while (v>1) {
        v-=1;
        const parent: usize=@intCast(input[v]);
        included[parent]+=@min(included[v],excluded[v]);
        excluded[parent]+=included[v];
    }
    return @min(included[0],excluded[0]);
}
