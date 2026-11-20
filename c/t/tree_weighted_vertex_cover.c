/* Uncompiled weighted tree vertex-cover draft. */
#include <stddef.h>
#include <stdint.h>
int64_t tree_weighted_vertex_cover(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 129) return -1;
    int64_t nv = input[0];
    if (nv < 1 || nv > 64 || length != (size_t)(2*nv)) return -1;
    size_t n = (size_t)nv;
    for (size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=(int64_t)v) return -1;
    int64_t included[64], excluded[64] = {0};
    for (size_t v=0; v<n; ++v) {
        int64_t w=input[n+v];
        if (w<0 || w>1000000) return -1;
        included[v]=w;
    }
    for (size_t v=n; v-- > 1;) {
        size_t p=(size_t)input[v];
        included[p]+=included[v]<excluded[v] ? included[v] : excluded[v];
        excluded[p]+=included[v];
    }
    return included[0]<excluded[0] ? included[0] : excluded[0];
}
