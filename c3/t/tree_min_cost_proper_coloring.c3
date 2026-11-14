// Uncompiled bounded minimum-cost proper tree coloring draft.
module tree_min_cost_proper_coloring;
fn long tree_min_cost_proper_coloring(long* input, usz length) @export("tree_min_cost_proper_coloring") {
    if (input==null || length<2 || length>1090) return -1;
    long nv=input[0], kv=input[1];
    if (nv<1 || nv>64 || kv<1 || kv>16) return -1;
    usz n=(usz)nv, k=(usz)kv;
    if (length!=n+1+n*k) return -1;
    for (usz v=1; v<n; v++) if (input[1+v]<0 || input[1+v]>=(long)v) return -1;
    long[1024] dp=zeroed;
    for (usz v=0; v<n; v++) for (usz c=0; c<k; c++) {
        long value=input[n+1+v*k+c];
        if (value<0 || value>1000000) return -1;
        dp[16*v+c]=value;
    }
    if (n>1 && k==1) return -2;
    for (usz child=n; child>1;) {
        child--;
        usz parent=(usz)input[1+child], best_color=0;
        long least=64000001, second=64000001;
        for (usz c=0; c<k; c++) {
            long value=dp[16*child+c];
            if (value<least) { second=least; least=value; best_color=c; }
            else if (value<second) second=value;
        }
        for (usz c=0; c<k; c++) dp[16*parent+c]+=c==best_color ? second : least;
    }
    long best=dp[0];
    for (usz c=1; c<k; c++) if (dp[c]<best) best=dp[c];
    return best;
}
