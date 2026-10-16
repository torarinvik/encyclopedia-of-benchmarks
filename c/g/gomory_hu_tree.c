#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define NMAX 8
static int flow(const int64_t *cap, int n, int source, int sink, int64_t *value, int *reach) {
    int64_t residual[64] = {0};
    for (int i = 0; i < n*n; ++i) residual[i] = cap[i];
    int parent[8], queue[8];
    int64_t total = 0;
    for (;;) {
        for (int i=0;i<n;++i) parent[i]=-1;
        parent[source]=source; int head=0, tail=0; queue[tail++]=source;
        while (head<tail && parent[sink]<0) {
            int u=queue[head++];
            for (int v=0;v<n;++v) if (residual[u*n+v]>0 && parent[v]<0) {
                parent[v]=u; if (v==sink) break; queue[tail++]=v;
            }
        }
        if (parent[sink]<0) break;
        int64_t amount=INT64_MAX;
        for (int v=sink;v!=source;v=parent[v]) if (residual[parent[v]*n+v]<amount) amount=residual[parent[v]*n+v];
        for (int v=sink;v!=source;v=parent[v]) { int u=parent[v]; residual[u*n+v]-=amount; residual[v*n+u]+=amount; }
        total+=amount;
    }
    for (int i=0;i<n;++i) reach[i]=0;
    int head=0,tail=0;queue[tail++]=source;reach[source]=1;
    while(head<tail){int u=queue[head++];for(int v=0;v<n;++v)if(!reach[v]&&residual[u*n+v]>0){reach[v]=1;queue[tail++]=v;}}
    *value=total; return 1;
}

int64_t gomory_hu_tree(const int64_t *a, size_t length) {
    if (!a || length<2 || length>65) return -1;
    int64_t n64=a[0]; if(n64<1||n64>NMAX||length!=1+(size_t)n64*(size_t)n64)return -1;
    int n=(int)n64; int64_t cap[64]={0};
    for(int i=0;i<n*n;++i){int64_t x=a[1+i];if(x<0||x>1000)return -1;cap[i]=x;}
    for(int i=0;i<n;++i)for(int j=0;j<n;++j)if(cap[i*n+j]!=(i==j?0:cap[j*n+i]))return -1;
    int parent[8]={0};int64_t weight[8]={0};parent[0]=-1;
    for(int s=1;s<n;++s){int t=parent[s],reach[8];int64_t f=0;flow(cap,n,s,t,&f,reach);weight[s]=f;
        for(int v=0;v<n;++v)if(v!=s&&parent[v]==t&&reach[v])parent[v]=s;
        if(t!=0&&reach[parent[t]]){parent[s]=parent[t];parent[t]=s;weight[s]=weight[t];weight[t]=f;}
    }
    int64_t pair[64]={0};
    for(int source=0;source<n;++source){int q[8],prev[8],head=0,tail=0;q[tail++]=source;for(int i=0;i<n;++i)prev[i]=-2;prev[source]=-1;
        while(head<tail){int u=q[head++];for(int v=0;v<n;++v){int w=-1;if(v!=u&&parent[v]==u)w=v;else if(v!=u&&parent[u]==v)w=u;if(w>=0&&prev[v]==-2){prev[v]=u;q[tail++]=v;}}}
        for(int target=0;target<n;++target)if(target!=source){int x=target;int64_t minimum=INT64_MAX;while(x!=source){int p=prev[x];int edge=(parent[x]==p)?x:p;if(weight[edge]<minimum)minimum=weight[edge];x=p;}pair[source*n+target]=minimum;}
    }
    uint64_t h=UINT64_C(14695981039346656037);
    for(int i=0;i<n*n;++i){uint64_t bits=(uint64_t)pair[i];for(int k=0;k<8;++k){h=(h^(bits&255))*UINT64_C(1099511628211);bits>>=8;}}
    int64_t result;
    memcpy(&result, &h, sizeof(result));
    return result;
}
