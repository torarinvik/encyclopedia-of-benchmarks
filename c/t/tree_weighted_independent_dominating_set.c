/* Uncompiled weighted independent tree domination draft. */
#include <stddef.h>
#include <stdint.h>
#define TWID_INF INT64_C(1000000000000)
static int64_t twid_min(int64_t a,int64_t b) { return a<b ? a : b; }
static int64_t twid_add(int64_t a,int64_t b) { return twid_min(TWID_INF,a+b); }
int64_t tree_weighted_independent_dominating_set(const int64_t *input,size_t length) {
    if (!input || length<2 || length>129) return -1;
    int64_t nv=input[0];
    if (nv<1 || nv>64 || length!=(size_t)(2*nv)) return -1;
    size_t n=(size_t)nv;
    for (size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=(int64_t)v) return -1;
    int64_t selected[64],covered[64],waiting[64]={0};
    for (size_t v=0; v<n; ++v) {
        int64_t w=input[n+v];
        if (w<0 || w>1000000) return -1;
        selected[v]=w; covered[v]=TWID_INF;
    }
    for (size_t v=n; v-- > 1;) {
        size_t p=(size_t)input[v];
        int64_t a=selected[v],b=covered[v],c=waiting[v];
        int64_t next=twid_min(twid_add(covered[p],twid_min(a,b)),twid_add(waiting[p],a));
        selected[p]=twid_add(selected[p],twid_min(b,c));
        waiting[p]=twid_add(waiting[p],b);
        covered[p]=next;
    }
    return twid_min(selected[0],covered[0]);
}
