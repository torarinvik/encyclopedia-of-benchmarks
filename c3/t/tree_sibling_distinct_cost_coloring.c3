// Independent bounded subset-assignment draft; not compiled or run.
module tree_sibling_distinct_cost_coloring;
fn long tree_sibling_distinct_cost_coloring(long* input, usz length) @export("tree_sibling_distinct_cost_coloring") {
    if (input==null || length<3 || length>354) return -1;
    if (input[0]<1 || input[0]>32 || input[1]<1 || input[1]>10) return -1;
    usz n=(usz)input[0], k=(usz)input[1];
    if (length!=n+1+n*k) return -1;
    for (usz v=1; v<n; v++) if (input[1+v]<0 || input[1+v]>=(long)v) return -1;
    for (usz i=0; i<n*k; i++) if (input[n+1+i]<0 || input[n+1+i]>1000000) return -1;
    long inf=1000000000000;
    usz states=(usz)1 << k;
    long[320] dp=zeroed;
    long[1024] current=zeroed;
    long[1024] next=zeroed;
    for (usz v=n; v>0;) {
        v--;
        for (usz color=0; color<k; color++) {
            for (usz mask=0; mask<states; mask++) current[mask]=inf;
            current[(usz)1<<color]=0;
            for (usz child=v+1; child<n; child++) {
                if (input[1+child]!=(long)v) continue;
                for (usz mask=0; mask<states; mask++) next[mask]=inf;
                for (usz mask=0; mask<states; mask++) {
                    if (current[mask]==inf) continue;
                    for (usz c=0; c<k; c++) {
                        usz bit=(usz)1<<c;
                        if ((mask&bit)!=0 || dp[10*child+c]==inf) continue;
                        usz target=mask|bit;
                        long candidate=current[mask]+dp[10*child+c];
                        if (candidate<next[target]) next[target]=candidate;
                    }
                }
                for (usz mask=0; mask<states; mask++) current[mask]=next[mask];
            }
            long best=inf;
            for (usz mask=0; mask<states; mask++) if (current[mask]<best) best=current[mask];
            dp[10*v+color]=best==inf ? inf : best+input[n+1+v*k+color];
        }
    }
    long best=inf;
    for (usz c=0; c<k; c++) if (dp[c]<best) best=dp[c];
    return best==inf ? -2 : best;
}
