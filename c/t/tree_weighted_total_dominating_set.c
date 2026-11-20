/* Uncompiled weighted total-domination tree draft. */
#include <stddef.h>
#include <stdint.h>
#define TWT_INF INT64_C(1000000000000)
static int64_t twt_min(int64_t a,int64_t b) { return a<b ? a : b; }
static int64_t twt_add(int64_t a,int64_t b) { return twt_min(TWT_INF,a+b); }
int64_t tree_weighted_total_dominating_set(const int64_t *input,size_t length) {
    if (!input || length<2 || length>129) return -1;
    int64_t nv=input[0];
    if (nv<1 || nv>64 || length!=(size_t)(2*nv)) return -1;
    size_t n=(size_t)nv;
    for (size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=(int64_t)v) return -1;
    int64_t weights[64], none[64][2]={{0}}, some[64][2];
    for (size_t v=0; v<n; ++v) {
        weights[v]=input[n+v];
        if (weights[v]<0 || weights[v]>1000000) return -1;
        some[v][0]=some[v][1]=TWT_INF;
    }
    int64_t root=TWT_INF;
    for (size_t v=n; v-- > 0;) {
        int64_t dp[2][2];
        for (int chosen=0; chosen<2; ++chosen) {
            int64_t own=chosen ? weights[v] : 0;
            dp[chosen][0]=twt_add(own,some[v][chosen]);
            dp[chosen][1]=twt_add(own,twt_min(none[v][chosen],some[v][chosen]));
        }
        if (v==0) { root=twt_min(dp[0][0],dp[1][0]); break; }
        size_t p=(size_t)input[v];
        for (int parent_chosen=0; parent_chosen<2; ++parent_chosen) {
            int64_t absent=dp[0][parent_chosen], present=dp[1][parent_chosen];
            int64_t next=twt_min(twt_add(some[p][parent_chosen],twt_min(absent,present)),
                                 twt_add(none[p][parent_chosen],present));
            none[p][parent_chosen]=twt_add(none[p][parent_chosen],absent);
            some[p][parent_chosen]=next;
        }
    }
    return root==TWT_INF ? -2 : root;
}
