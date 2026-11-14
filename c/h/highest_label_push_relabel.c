#include <stddef.h>
#include <stdint.h>

int64_t highest_label_push_relabel(const int64_t *input, size_t length) {
    if (!input || length < 4 || length > 197) return -1;
    int64_t nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    int n=(int)nv, m=(int)mv, source=(int)sv-1, sink=(int)tv-1;
    if (length != (size_t)(4+3*m)) return -1;
    int64_t residual[16][16]={{0}}, excess[16]={0};
    int height[16]={0};
    for (int i=0; i<m; ++i) {
        int64_t u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[u-1][v-1] += capacity;
    }
    height[source]=n;
    for (int v=0; v<n; ++v) {
        int64_t amount=residual[source][v];
        residual[source][v]=0;
        residual[v][source]+=amount;
        excess[v]+=amount;
        excess[source]-=amount;
    }
    for (;;) {
        int u=-1;
        for (int v=0; v<n; ++v) {
            if (v!=source && v!=sink && excess[v]>0 && (u<0 || height[v]>height[u])) u=v;
        }
        if (u<0) return excess[sink];
        int destination=-1, minimum=2*n+1;
        for (int v=0; v<n; ++v) if (residual[u][v]>0) {
            if (height[v]<minimum) minimum=height[v];
            if (destination<0 && height[u]==height[v]+1) destination=v;
        }
        if (destination<0) {
            if (minimum>2*n) return -1;
            height[u]=minimum+1;
        } else {
            int64_t amount=excess[u]<residual[u][destination] ? excess[u] : residual[u][destination];
            residual[u][destination]-=amount;
            residual[destination][u]+=amount;
            excess[u]-=amount;
            excess[destination]+=amount;
        }
    }
}
