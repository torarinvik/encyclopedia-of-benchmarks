// Uncompiled weighted tree dominating-set draft.
module tree_weighted_dominating_set;
const long TWD_INF=1000000000000;
fn long twd_min(long a,long b) { return a<b ? a : b; }
fn long twd_add(long a,long b) { return twd_min(TWD_INF,a+b); }
fn long tree_weighted_dominating_set(long* input,usz length) @export("tree_weighted_dominating_set") {
    if (input==null || length<2 || length>129) return -1;
    long nv=input[0];
    if (nv<1 || nv>64 || length!=(usz)(2*nv)) return -1;
    usz n=(usz)nv;
    for (usz v=1; v<n; v++) if (input[v]<0 || input[v]>=(long)v) return -1;
    long[64] selected=zeroed, covered=zeroed, waiting=zeroed;
    for (usz v=0; v<n; v++) {
        long weight=input[n+v];
        if (weight<0 || weight>1000000) return -1;
        selected[v]=weight; covered[v]=TWD_INF;
    }
    for (usz v=n; v>1;) {
        v--; usz p=(usz)input[v];
        long a=selected[v], b=covered[v], c=waiting[v];
        long next=twd_min(twd_add(covered[p],twd_min(a,b)),twd_add(waiting[p],a));
        selected[p]=twd_add(selected[p],twd_min(twd_min(a,b),c));
        waiting[p]=twd_add(waiting[p],b);
        covered[p]=next;
    }
    return twd_min(selected[0],covered[0]);
}
