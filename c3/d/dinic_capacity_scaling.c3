module dinic_capacity_scaling;

fn long send_scaled(usz u, usz sink, long amount, long* residual, long* level,
                    usz* cursor, usz n, long threshold) {
    if (u==sink) return amount;
    while (cursor[u]<n) {
        usz v=cursor[u], edge=16*u+v;
        if (level[v]==level[u]+1 && residual[edge]>=threshold) {
            long bound=amount<residual[edge] ? amount : residual[edge];
            long pushed=send_scaled(v,sink,bound,residual,level,cursor,n,threshold);
            if (pushed>0) { residual[edge]-=pushed; residual[16*v+u]+=pushed; return pushed; }
        }
        cursor[u]++;
    }
    return 0;
}

fn long dinic_capacity_scaling(long* input, usz length) @export("dinic_capacity_scaling") {
    if (input==null || length<4 || length>197) return -1;
    long nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    usz n=nv.usz(), m=mv.usz(), source=(sv-1).usz(), sink=(tv-1).usz();
    if (length != 4+3*m) return -1;
    long[256] residual=zeroed;
    for (usz i=0; i<m; i++) {
        long u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[(u-1).usz()*16+(v-1).usz()] += capacity;
    }
    long greatest=0;
    for (usz i=0; i<256; i++) if (residual[i]>greatest) greatest=residual[i];
    long threshold=1, flow=0;
    while (threshold<=greatest/2) threshold*=2;
    if (greatest==0) threshold=0;
    while (threshold>0) {
        while (true) {
            long[16] level; usz[16] queue;
            for (usz i=0; i<16; i++) level[i]=-1;
            usz head=0, tail=1; level[source]=0; queue[0]=source;
            while (head<tail) {
                usz u=queue[head++];
                for (usz v=0; v<n; v++) if (level[v]<0 && residual[16*u+v]>=threshold) {
                    level[v]=level[u]+1; queue[tail++]=v;
                }
            }
            if (level[sink]<0) break;
            usz[16] cursor=zeroed;
            while (true) {
                long pushed=send_scaled(source,sink,6401,&residual[0],&level[0],&cursor[0],n,threshold);
                if (pushed==0) break;
                flow+=pushed;
            }
        }
        threshold/=2;
    }
    return flow;
}
