// Uncompiled weighted tree vertex-cover draft.
module tree_weighted_vertex_cover;
fn long tree_weighted_vertex_cover(long* input, usz length) @export("tree_weighted_vertex_cover") {
    if (input==null || length<2 || length>129) return -1;
    long nv=input[0];
    if (nv<1 || nv>64 || length!=(usz)(2*nv)) return -1;
    usz n=(usz)nv;
    for (usz v=1; v<n; v++) if (input[v]<0 || input[v]>=(long)v) return -1;
    long[64] included=zeroed, excluded=zeroed;
    for (usz v=0; v<n; v++) {
        long weight=input[n+v];
        if (weight<0 || weight>1000000) return -1;
        included[v]=weight;
    }
    for (usz v=n; v>1;) {
        v--; usz parent=(usz)input[v];
        included[parent]+=included[v]<excluded[v] ? included[v] : excluded[v];
        excluded[parent]+=included[v];
    }
    return included[0]<excluded[0] ? included[0] : excluded[0];
}
