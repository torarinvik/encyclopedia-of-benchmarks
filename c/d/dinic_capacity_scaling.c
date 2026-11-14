#include <stddef.h>
#include <stdint.h>

static int send_scaled(int u, int sink, int amount, int64_t residual[16][16],
                       const int level[16], int cursor[16], int n, int64_t threshold) {
    if (u == sink) return amount;
    while (cursor[u] < n) {
        int v = cursor[u];
        if (level[v] == level[u]+1 && residual[u][v] >= threshold) {
            int available = residual[u][v] < amount ? (int)residual[u][v] : amount;
            int pushed = send_scaled(v, sink, available, residual, level, cursor, n, threshold);
            if (pushed) { residual[u][v] -= pushed; residual[v][u] += pushed; return pushed; }
        }
        ++cursor[u];
    }
    return 0;
}

int64_t dinic_capacity_scaling(const int64_t *input, size_t length) {
    if (!input || length < 4 || length > 197) return -1;
    int64_t nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    int n=(int)nv, m=(int)mv, source=(int)sv-1, sink=(int)tv-1;
    if (length != (size_t)(4+3*m)) return -1;
    int64_t residual[16][16]={{0}};
    for (int i=0; i<m; ++i) {
        int64_t u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[u-1][v-1] += capacity;
    }
    int64_t greatest=0;
    for (int u=0; u<n; ++u) for (int v=0; v<n; ++v)
        if (residual[u][v]>greatest) greatest=residual[u][v];
    int64_t threshold=1, flow=0;
    while (threshold <= greatest/2) threshold *= 2;
    if (!greatest) threshold=0;
    for (; threshold; threshold/=2) {
        for (;;) {
            int level[16], queue[16], head=0, tail=0;
            for (int i=0; i<n; ++i) level[i]=-1;
            level[source]=0; queue[tail++]=source;
            while (head<tail) {
                int u=queue[head++];
                for (int v=0; v<n; ++v) if (level[v]<0 && residual[u][v]>=threshold) {
                    level[v]=level[u]+1; queue[tail++]=v;
                }
            }
            if (level[sink]<0) break;
            int cursor[16]={0};
            for (;;) {
                int sent=send_scaled(source,sink,6401,residual,level,cursor,n,threshold);
                if (!sent) break;
                flow+=sent;
            }
        }
    }
    return flow;
}
