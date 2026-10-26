/* Clean-room high-/low-degree vertex-cover reduction profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N=16, MAX_M=64, MAX_INPUT=131, MAX_FIELDS=133 };

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits=(uint64_t)value;
    for (size_t b=0;b<8;++b) { out[at+b]=(uint8_t)(bits&255u); bits>>=8; }
}

int64_t vertex_cover_kernelization(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if (!input || length<3 || length>MAX_INPUT) return -1;
    int64_t n64=input[0],m64=input[1],k64=input[2];
    if (n64<1 || n64>MAX_N || m64<0 || m64>MAX_M || k64<0 || k64>MAX_N || length!=3+2*(size_t)m64) return -1;
    size_t n=(size_t)n64,m=(size_t)m64;
    uint8_t edge[MAX_N][MAX_N]={{0}};
    int64_t previous_u=-1,previous_v=-1;
    for (size_t e=0;e<m;++e) {
        int64_t u=input[3+2*e],v=input[4+2*e];
        if (u<0 || v<=u || v>=n64 || u<previous_u || (u==previous_u && v<=previous_v)) return -1;
        edge[u][v]=edge[v][u]=1; previous_u=u; previous_v=v;
    }
    if (!output) return -2;
    uint8_t active[MAX_N]={0}; for (size_t i=0;i<n;++i) active[i]=1;
    int64_t k=k64; uint64_t forced=0; int infeasible=0;
    for (;;) {
        if (k<0) { infeasible=1; break; }
        size_t chosen=n,neighbor=n; int chosen_kind=0;
        for (size_t u=0;u<n;++u) if (active[u]) {
            size_t degree=0;
            for (size_t v=0;v<n;++v) degree+=edge[u][v]!=0;
            if (degree==0) { chosen=u; chosen_kind=1; break; }
        }
        if (chosen_kind==1) { active[chosen]=0; continue; }
        for (size_t u=0;u<n;++u) if (active[u]) {
            size_t degree=0,only=n;
            for (size_t v=0;v<n;++v) if (edge[u][v]) { ++degree; only=v; }
            if (degree==1) { chosen=u; neighbor=only; chosen_kind=2; break; }
        }
        if (!chosen_kind) for (size_t u=0;u<n;++u) if (active[u]) {
            size_t degree=0; for (size_t v=0;v<n;++v) degree+=edge[u][v]!=0;
            if ((int64_t)degree>k) { chosen=u; chosen_kind=3; break; }
        }
        if (!chosen_kind) break;
        size_t forced_vertex=chosen_kind==2?neighbor:chosen;
        forced |= UINT64_C(1)<<forced_vertex; active[forced_vertex]=0; --k;
        for (size_t v=0;v<n;++v) edge[forced_vertex][v]=edge[v][forced_vertex]=0;
    }
    int64_t staged[MAX_FIELDS]={0}; size_t count=0;
    staged[count++]=infeasible?0:1; staged[count++]=k; staged[count++]=(int64_t)forced;
    uint64_t active_mask=0; for (size_t v=0;v<n;++v) if (active[v]) active_mask|=UINT64_C(1)<<v;
    staged[count++]=(int64_t)active_mask;
    size_t remaining_edges=0; for (size_t u=0;u<n;++u) for (size_t v=u+1;v<n;++v) remaining_edges+=edge[u][v]!=0;
    staged[count++]=(int64_t)remaining_edges;
    for (size_t u=0;u<n;++u) for (size_t v=u+1;v<n;++v) if (edge[u][v]) { staged[count++]=(int64_t)u; staged[count++]=(int64_t)v; }
    if (capacity < 8*count) return -2;
    for (size_t i=0;i<count;++i) put_i64(output,8*i,staged[i]);
    return (int64_t)(8*count);
}
