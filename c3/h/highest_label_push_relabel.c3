module highest_label_push_relabel;

fn long highest_label_push_relabel(long* input, usz length) @export("highest_label_push_relabel") {
    if (input==null || length<4 || length>197) return -1;
    long nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    usz n=nv.usz(), m=mv.usz(), source=(sv-1).usz(), sink=(tv-1).usz();
    if (length!=4+3*m) return -1;
    long[256] residual=zeroed;
    long[16] excess=zeroed, height=zeroed;
    for (usz i=0; i<m; i++) {
        long u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[16*(u-1).usz()+(v-1).usz()]+=capacity;
    }
    height[source]=nv;
    for (usz v=0; v<n; v++) {
        long amount=residual[16*source+v]; residual[16*source+v]=0;
        residual[16*v+source]+=amount; excess[v]+=amount; excess[source]-=amount;
    }
    while (true) {
        long active=-1;
        for (usz v=0; v<n; v++) {
            if (v!=source && v!=sink && excess[v]>0 && (active<0 || height[v]>height[active])) active=(long)v;
        }
        if (active<0) return excess[sink];
        usz u=active.usz();
        long destination=-1, minimum=2*nv+1;
        for (usz v=0; v<n; v++) if (residual[16*u+v]>0) {
            if (height[v]<minimum) minimum=height[v];
            if (destination<0 && height[u]==height[v]+1) destination=(long)v;
        }
        if (destination<0) {
            if (minimum>2*nv) return -1;
            height[u]=minimum+1;
        } else {
            usz v=destination.usz();
            long amount=excess[u]<residual[16*u+v] ? excess[u] : residual[16*u+v];
            residual[16*u+v]-=amount; residual[16*v+u]+=amount; excess[u]-=amount; excess[v]+=amount;
        }
    }
}
