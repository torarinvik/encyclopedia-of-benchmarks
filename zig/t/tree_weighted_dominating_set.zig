// Uncompiled weighted tree dominating-set draft.
const inf: i64 = 1_000_000_000_000;
fn add(a: i64, b: i64) i64 { return @min(inf,a+b); }
export fn tree_weighted_dominating_set(input: [*c]const i64, length: usize) i64 {
    if (input==null or length<2 or length>129) return -1;
    const nv=input[0];
    if (nv<1 or nv>64 or length!=@as(usize,@intCast(2*nv))) return -1;
    const n: usize=@intCast(nv);
    for (1..n) |v| if (input[v]<0 or input[v]>=@as(i64,@intCast(v))) { return -1; };
    var selected=[_]i64{0} ** 64;
    var covered=[_]i64{inf} ** 64;
    var waiting=[_]i64{0} ** 64;
    for (0..n) |v| {
        const weight=input[n+v];
        if (weight<0 or weight>1_000_000) return -1;
        selected[v]=weight;
    }
    var v=n;
    while (v>1) {
        v-=1;
        const p: usize=@intCast(input[v]);
        const a=selected[v]; const b=covered[v]; const c=waiting[v];
        const next=@min(add(covered[p],@min(a,b)),add(waiting[p],a));
        selected[p]=add(selected[p],@min(@min(a,b),c));
        waiting[p]=add(waiting[p],b);
        covered[p]=next;
    }
    return @min(selected[0],covered[0]);
}
