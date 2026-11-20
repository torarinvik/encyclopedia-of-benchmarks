// Uncompiled weighted total-domination tree draft.
module tree_weighted_total_dominating_set;
const long TWT_INF=1000000000000;
fn long twt_min(long a,long b) { return a<b ? a : b; }
fn long twt_add(long a,long b) { return twt_min(TWT_INF,a+b); }
fn long tree_weighted_total_dominating_set(long* input,usz length) @export("tree_weighted_total_dominating_set") {
    if (input==null || length<2 || length>129) return -1;
    long nv=input[0];
    if (nv<1 || nv>64 || length!=(usz)(2*nv)) return -1;
    usz n=(usz)nv;
    for (usz v=1; v<n; v++) if (input[v]<0 || input[v]>=(long)v) return -1;
    long[64] weights=zeroed;
    long[128] none=zeroed, some=zeroed;
    for (usz v=0; v<n; v++) {
        weights[v]=input[n+v];
        if (weights[v]<0 || weights[v]>1000000) return -1;
        some[2*v]=TWT_INF; some[2*v+1]=TWT_INF;
    }
    long root=TWT_INF;
    for (usz v=n; v>0;) {
        v--;
        long[4] dp=zeroed;
        for (usz chosen=0; chosen<2; chosen++) {
            long own=chosen==1 ? weights[v] : 0;
            dp[2*chosen]=twt_add(own,some[2*v+chosen]);
            dp[2*chosen+1]=twt_add(own,twt_min(none[2*v+chosen],some[2*v+chosen]));
        }
        if (v==0) { root=twt_min(dp[0],dp[2]); break; }
        usz p=(usz)input[v];
        for (usz chosen=0; chosen<2; chosen++) {
            long a=dp[chosen], b=dp[2+chosen]; usz index=2*p+chosen;
            long next=twt_min(twt_add(some[index],twt_min(a,b)),twt_add(none[index],b));
            none[index]=twt_add(none[index],a); some[index]=next;
        }
    }
    return root==TWT_INF ? -2 : root;
}
