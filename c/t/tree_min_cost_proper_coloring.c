/* Uncompiled bounded minimum-cost proper tree coloring draft. */
#include <stddef.h>
#include <stdint.h>

int64_t tree_min_cost_proper_coloring(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 1090) return -1;
    int64_t nv=input[0], kv=input[1];
    if (nv<1 || nv>64 || kv<1 || kv>16) return -1;
    size_t n=(size_t)nv, k=(size_t)kv;
    if (length != n+1+n*k) return -1;
    for (size_t v=1; v<n; ++v)
        if (input[1+v]<0 || input[1+v]>=(int64_t)v) return -1;
    int64_t dp[64][16];
    for (size_t v=0; v<n; ++v) for (size_t c=0; c<k; ++c) {
        int64_t value=input[n+1+v*k+c];
        if (value<0 || value>1000000) return -1;
        dp[v][c]=value;
    }
    if (n>1 && k==1) return -2;
    for (size_t child=n; child-- > 1;) {
        size_t parent=(size_t)input[1+child], least_color=0;
        int64_t least=INT64_MAX, second=INT64_MAX;
        for (size_t c=0; c<k; ++c) {
            int64_t value=dp[child][c];
            if (value<least) { second=least; least=value; least_color=c; }
            else if (value<second) second=value;
        }
        for (size_t c=0; c<k; ++c)
            dp[parent][c] += c==least_color ? second : least;
    }
    int64_t best=dp[0][0];
    for (size_t c=1; c<k; ++c) if (dp[0][c]<best) best=dp[0][c];
    return best;
}
