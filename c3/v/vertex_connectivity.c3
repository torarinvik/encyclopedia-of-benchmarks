module vertex_connectivity;

fn long vertex_connectivity(long* input, usz length) @export("vertex_connectivity") {
    const usz N=10, M=45, MAX_INPUT=92, DN=20;
    if (input==null || length<2 || length>MAX_INPUT) return -1;
    if (input[0]<0 || input[0]>(long)N || input[1]<0 || input[1]>(long)M) return -1;
    usz n=(usz)input[0], m=(usz)input[1];
    if (length!=2+2*m) return -1;
    ulong adjacency[N]={0};
    for (usz e=0; e<m; e++) {
        long left=input[2+2*e], right=input[3+2*e];
        if (left<0 || right<0 || (ulong)left>=(ulong)n || (ulong)right>=(ulong)n) return -1;
        if (left!=right) {
            adjacency[(usz)left] |= 1ul << (ulong)right;
            adjacency[(usz)right] |= 1ul << (ulong)left;
        }
    }
    if (n<=1) return 0;
    ulong reached=1ul; usz graph_queue[N]; usz graph_head=0, graph_tail=0; graph_queue[graph_tail++]=0;
    while (graph_head<graph_tail) {
        usz u=graph_queue[graph_head++];
        for (usz v=0; v<n; v++) {
            ulong bit=1ul << (ulong)v;
            if ((adjacency[u]&bit)!=0ul && (reached&bit)==0ul) { reached|=bit; graph_queue[graph_tail++]=v; }
        }
    }
    if (reached!=((1ul << (ulong)n)-1ul)) return 0;
    long best=(long)n-1;
    for (usz source=0; source<n; source++) {
        for (usz target=source+1; target<n; target++) {
            if ((adjacency[source]&(1ul << (ulong)target))!=0ul) continue;
            long residual[DN*DN];
            for (usz i=0; i<DN*DN; i++) residual[i]=0;
            usz nodes=2*n;
            for (usz v=0; v<n; v++) {
                long capacity=(v==source || v==target) ? (long)n : 1;
                residual[(2*v)*DN+(2*v+1)]=capacity;
            }
            for (usz u=0; u<n; u++) {
                for (usz v=u+1; v<n; v++) {
                    if ((adjacency[u]&(1ul << (ulong)v))!=0ul) {
                        residual[(2*u+1)*DN+2*v]=1;
                        residual[(2*v+1)*DN+2*u]=1;
                    }
                }
            }
            usz start=2*source+1, sink=2*target;
            long flow=0;
            while (flow<best) {
                long parent[DN]; usz queue[DN];
                for (usz v=0; v<nodes; v++) parent[v]=-1;
                parent[start]=(long)start;
                usz head=0, tail=0; queue[tail++]=start;
                while (head<tail && parent[sink]<0) {
                    usz u=queue[head++];
                    for (usz v=0; v<nodes; v++) {
                        if (parent[v]<0 && residual[u*DN+v]>0) {
                            parent[v]=(long)u; queue[tail++]=v;
                            if (v==sink) break;
                        }
                    }
                }
                if (parent[sink]<0) break;
                long amount=best-flow;
                for (usz v=sink; v!=start; v=(usz)parent[v]) {
                    usz u=(usz)parent[v]; if (residual[u*DN+v]<amount) amount=residual[u*DN+v];
                }
                for (usz v=sink; v!=start; v=(usz)parent[v]) {
                    usz u=(usz)parent[v]; residual[u*DN+v]-=amount; residual[v*DN+u]+=amount;
                }
                flow+=amount;
            }
            if (flow<best) best=flow;
            if (best==0) return 0;
        }
    }
    return best;
}
