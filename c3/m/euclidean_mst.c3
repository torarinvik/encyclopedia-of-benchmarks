module euclidean_mst;

const int MAX_POINTS = 8;
const int MAX_EDGES = MAX_POINTS * (MAX_POINTS - 1) / 2;
const usz MAX_INPUT_LENGTH = 18;
const int MAX_OUTPUT_WORDS = 2 * MAX_POINTS - 1;

struct Point { long x; long y; }
struct Edge { int u; int v; long weight; }

fn long orientation(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
fn long incircle(Point a, Point b, Point c, Point d) {
    long ax=a.x-d.x, ay=a.y-d.y, bx=b.x-d.x, by=b.y-d.y, cx=c.x-d.x, cy=c.y-d.y;
    return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx) + (cx*cx+cy*cy)*(ax*by-ay*bx);
}
fn bool general_position(Point[MAX_POINTS] points, int n) {
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++)
        if (points[a].x==points[b].x && points[a].y==points[b].y) return false;
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++) {
        if (orientation(points[a],points[b],points[c])==0) return false;
        for (int d=0;d<n;d++) if (d!=a && d!=b && d!=c && incircle(points[a],points[b],points[c],points[d])==0) return false;
    }
    return true;
}
fn int find_root(int[MAX_POINTS]* parent, int vertex) {
    int current=vertex;
    while (parent[current]!=current) { parent[current]=parent[parent[current]]; current=parent[current]; }
    return current;
}
fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits=(ulong)value;
    for (usz byte=0;byte<8;byte++) { output[offset+byte]=(char)(bits&255); bits>>=8; }
}

fn long euclidean_mst(long* input, usz length, char* output, usz output_capacity)
    @export("euclidean_mst") {
    if (input==null || length<1 || length>MAX_INPUT_LENGTH) return -1;
    long raw_n=input[0];
    if (raw_n<1 || raw_n>MAX_POINTS) return -1;
    int n=(int)raw_n;
    if (length!=(usz)(1+2*n)) return -1;
    Point[MAX_POINTS] points=zeroed;
    for (int i=0;i<n;i++) {
        points[i].x=input[1+2*i]; points[i].y=input[2+2*i];
        if (points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10) return -1;
    }
    if (!general_position(points,n)) return -1;
    usz output_words=(usz)(2*n-1), output_bytes=8*output_words;
    if (output==null || output_capacity<output_bytes) return -2;

    bool[MAX_POINTS][MAX_POINTS] candidate=zeroed;
    if (n==2) { candidate[0][1]=true; candidate[1][0]=true; }
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++) {
        long turn=orientation(points[a],points[b],points[c]);
        bool empty=true;
        for (int d=0;d<n;d++) {
            if (d==a || d==b || d==c) continue;
            long determinant=incircle(points[a],points[b],points[c],points[d]);
            if ((determinant>0)==(turn>0)) { empty=false; break; }
        }
        if (empty) {
            candidate[a][b]=true; candidate[b][a]=true;
            candidate[a][c]=true; candidate[c][a]=true;
            candidate[b][c]=true; candidate[c][b]=true;
        }
    }
    Edge[MAX_EDGES] edges=zeroed;
    int edge_count=0;
    for (int u=0;u<n;u++) for (int v=u+1;v<n;v++) if (candidate[u][v]) {
        long dx=points[u].x-points[v].x, dy=points[u].y-points[v].y;
        Edge edge={u,v,dx*dx+dy*dy};
        int at=edge_count++;
        while (at>0) {
            Edge previous=edges[at-1];
            if (previous.weight<edge.weight || (previous.weight==edge.weight &&
                (previous.u<edge.u || (previous.u==edge.u && previous.v<=edge.v)))) break;
            edges[at]=previous; at--;
        }
        edges[at]=edge;
    }
    int[MAX_POINTS] parent=zeroed, sizes=zeroed;
    for (int i=0;i<n;i++) { parent[i]=i; sizes[i]=1; }
    long[MAX_OUTPUT_WORDS] words=zeroed;
    words[0]=n-1;
    int selected=0;
    for (int i=0;i<edge_count && selected<n-1;i++) {
        int left=find_root(&parent,edges[i].u), right=find_root(&parent,edges[i].v);
        if (left==right) continue;
        if (sizes[left]<sizes[right]) { int temporary=left; left=right; right=temporary; }
        parent[right]=left; sizes[left]+=sizes[right];
        words[1+2*selected]=edges[i].u; words[2+2*selected]=edges[i].v; selected++;
    }
    if (selected!=n-1) return -1;
    for (usz word=0;word<output_words;word++) store_i64_le(output,8*word,words[word]);
    return (long)output_bytes;
}
