// Uncompiled weighted independent tree domination draft.
module tree_weighted_independent_dominating_set;
const long TWID_INF=1000000000000;
fn long twid_min(long a,long b) { return a<b ? a : b; }
fn long twid_add(long a,long b) { return twid_min(TWID_INF,a+b); }
fn long tree_weighted_independent_dominating_set(long* input,usz length) @export("tree_weighted_independent_dominating_set") {
    if (input==null || length<2 || length>129) return -1;
    long nv=input[0];
    if (nv<1 || nv>64 || length!=(usz)(2*nv)) return -1;
    usz n=(usz)nv;
    for (usz v=1; v<n; v++) if (input[v]<0 || input[v]>=(long)v) return -1;
    long[64] selected=zeroed, covered=zeroed, waiting=zeroed;
    for (usz v=0; v<n; v++) {
        long weight=input[n+v];
        if (weight<0 || weight>1000000) return -1;
        selected[v]=weight; covered[v]=TWID_INF;
    }
    for (usz v=n; v>1;) {
        v--; usz p=(usz)input[v];
        long a=selected[v], b=covered[v], c=waiting[v];
        long next=twid_min(twid_add(covered[p],twid_min(a,b)),twid_add(waiting[p],a));
        selected[p]=twid_add(selected[p],twid_min(b,c));
        waiting[p]=twid_add(waiting[p],b); covered[p]=next;
    }
    return twid_min(selected[0],covered[0]);
}
