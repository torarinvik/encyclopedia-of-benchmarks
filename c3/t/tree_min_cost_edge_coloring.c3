// Uncompiled matching-sensitivity tree edge-coloring draft.
module tree_min_cost_edge_coloring;
const long TEC_INF = 1000000000000000;

fn long tec_assignment(usz d, usz width, long* cost, long* deletion) {
    long[17] row_dual = zeroed, col_dual = zeroed;
    usz[17] owner = zeroed;
    for (usz row=1; row<=d; row++) {
        usz[17] previous = zeroed;
        bool[17] used = zeroed;
        long[17] slack;
        for (usz col=0; col<=width; col++) slack[col]=TEC_INF;
        owner[0]=row;
        usz col=0;
        while (true) {
            used[col]=true;
            usz active=owner[col], next_col=0;
            long step=TEC_INF;
            for (usz candidate=1; candidate<=width; candidate++) {
                if (used[candidate]) continue;
                long reduced=cost[16*(active-1)+candidate-1]-row_dual[active]-col_dual[candidate];
                if (reduced<slack[candidate]) { slack[candidate]=reduced; previous[candidate]=col; }
                if (slack[candidate]<step) { step=slack[candidate]; next_col=candidate; }
            }
            if (next_col==0) return -1;
            for (usz candidate=0; candidate<=width; candidate++) {
                if (used[candidate]) { row_dual[owner[candidate]]+=step; col_dual[candidate]-=step; }
                else if (candidate!=0) slack[candidate]-=step;
            }
            col=next_col;
            if (owner[col]==0) break;
        }
        while (col!=0) { usz parent=previous[col]; owner[col]=owner[parent]; col=parent; }
    }
    long base=0;
    usz free_col=width;
    for (usz col=0; col<width; col++) {
        if (owner[col+1]!=0) base+=cost[16*(owner[col+1]-1)+col];
        else free_col=col;
    }
    if (width==d) return base;
    if (free_col==width) return -1;
    long[16] distance, updated;
    for (usz col=0; col<width; col++) distance[col]=TEC_INF;
    distance[free_col]=0;
    for (usz pass=0; pass<d; pass++) {
        for (usz col=0; col<width; col++) updated[col]=distance[col];
        for (usz col=0; col<width; col++) {
            if (owner[col+1]==0) continue;
            usz row=owner[col+1]-1;
            for (usz dest=0; dest<width; dest++) if (distance[dest]!=TEC_INF) {
                long value=cost[16*row+dest]-cost[16*row+col]+distance[dest];
                if (value<updated[col]) updated[col]=value;
            }
        }
        for (usz col=0; col<width; col++) distance[col]=updated[col];
    }
    for (usz col=0; col<width; col++) {
        if (distance[col]==TEC_INF) return -1;
        deletion[col]=base+distance[col];
    }
    return base;
}

fn long tree_min_cost_edge_coloring(long* input, usz length) @export("tree_min_cost_edge_coloring") {
    if (input==null || length<2 || length>82) return -1;
    long nv=input[0], kv=input[1];
    if (nv<1 || nv>64 || kv<1 || kv>16) return -1;
    usz n=(usz)nv, k=(usz)kv;
    if (length!=n+1+k) return -1;
    usz[64] parents=zeroed, degree=zeroed, child_count=zeroed;
    for (usz vertex=1; vertex<n; vertex++) {
        long raw=input[1+vertex];
        if (raw<0 || raw>=(long)vertex) return -1;
        parents[vertex]=(usz)raw;
        degree[(usz)raw]++; degree[vertex]++;
    }
    long[16] prices;
    for (usz color=0; color<k; color++) {
        long value=input[n+1+color];
        if (value<0 || value>1000000) return -1;
        prices[color]=value;
    }
    for (usz vertex=0; vertex<n; vertex++) if (degree[vertex]>k) return -2;
    for (usz color=1; color<k; color++) {
        long value=prices[color]; usz j=color;
        while (j>0 && prices[j-1]>value) { prices[j]=prices[j-1]; j--; }
        prices[j]=value;
    }
    usz[1024] children=zeroed;
    for (usz vertex=1; vertex<n; vertex++) {
        usz parent=parents[vertex];
        children[16*parent+child_count[parent]++]=vertex;
    }
    long[1024] tables=zeroed;
    for (usz vertex=n; vertex>0;) {
        vertex--;
        usz d=child_count[vertex];
        if (d==0) continue;
        bool saturated=vertex==0 && d==k;
        usz width=saturated ? d : d+1;
        long[256] cost=zeroed; long[16] deletion=zeroed;
        for (usz row=0; row<d; row++) {
            usz child=children[16*vertex+row];
            for (usz col=0; col<width; col++) {
                usz index=col<child_count[child] ? col : child_count[child];
                cost[16*row+col]=prices[col]+tables[16*child+index];
            }
        }
        long base=tec_assignment(d,width,&cost[0],&deletion[0]);
        if (base<0) return -1;
        if (saturated) tables[16*vertex]=base;
        else for (usz col=0; col<width; col++) tables[16*vertex+col]=deletion[col];
    }
    return child_count[0]==k ? tables[0] : tables[child_count[0]];
}
