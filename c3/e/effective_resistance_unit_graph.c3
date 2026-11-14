// Uncompiled and unexecuted matrix-tree draft.
module effective_resistance_unit_graph;
fn long resistance_minor(long[36] lap, int n, int first, int second) {
    long[36] a = {}; int rows = 0;
    for (int i=0;i<n;i++) if (i!=first && i!=second) {
        int col=0;
        for (int j=0;j<n;j++) if (j!=first && j!=second) a[rows*6+col++]=lap[i*6+j];
        rows++;
    }
    if (rows == 0) return 1;
    long prev=1;
    for (int k=0;k<rows-1;k++) {
        long pivot=a[k*6+k]; if (pivot == 0) return 0;
        for (int i=k+1;i<rows;i++) for (int j=k+1;j<rows;j++) a[i*6+j]=(a[i*6+j]*pivot-a[i*6+k]*a[k*6+j])/prev;
        for (int i=k+1;i<rows;i++) a[i*6+k]=0;
        prev=pivot;
    }
    return a[(rows-1)*6+rows-1];
}
fn long effective_resistance_unit_graph(long* input, usz length) @export("effective_resistance_unit_graph") {
    if (input==null || length<4 || length>35) return -1;
    long nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>6 || mv<0 || mv>15 || sv<0 || sv>=nv || tv<0 || tv>=nv || sv==tv || length!=(usz)(4+2*mv)) return -1;
    int n=(int)nv, m=(int)mv, s=(int)sv, t=(int)tv;
    long[36] lap={}; bool[36] seen={};
    for (int i=0;i<m;i++) {
        long uv=input[4+2*i], vv=input[5+2*i];
        if (uv<0 || uv>=nv || vv<0 || vv>=nv || uv==vv) return -1;
        int u=(int)uv, v=(int)vv;
        if (seen[u*6+v]) return -1;
        seen[u*6+v]=true;seen[v*6+u]=true;
        lap[u*6+u]++;lap[v*6+v]++;lap[u*6+v]--;lap[v*6+u]--;
    }
    long trees=resistance_minor(lap,n,t,-1); if (trees<=0) return -1;
    long forests=resistance_minor(lap,n,s,t), a=trees, b=forests;
    while (b != 0) { long r=a%b; a=b; b=r; }
    return forests/a*65536+trees/a;
}
