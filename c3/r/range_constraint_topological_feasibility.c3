// Independent event-graph draft; compilation and output remain unverified.
module range_constraint_topological_feasibility;
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

struct RctGraph {
    long* head; long* degree; long* first; long* to; long* next;
    usz nodes; usz edges;
}
struct RctTrees { long* down; long* up; long* any; }

fn usz rct_node(RctGraph* g, bool first) {
    usz node=g.nodes++;
    g.head[node]=-1; g.degree[node]=0; g.first[node]=first ? 1 : 0;
    return node;
}
fn void rct_edge(RctGraph* g, usz source, usz target) {
    usz edge=g.edges++;
    g.to[edge]=(long)target; g.next[edge]=g.head[source]; g.head[source]=(long)edge;
    g.degree[target]++;
}
fn void rct_build(RctGraph* g, RctTrees* t, usz node, usz left, usz right) {
    t.down[node]=(long)rct_node(g,false); t.up[node]=(long)rct_node(g,false); t.any[node]=(long)rct_node(g,true);
    if (right-left==1) {
        rct_edge(g,(usz)t.down[node],left); rct_edge(g,left,(usz)t.up[node]); rct_edge(g,left,(usz)t.any[node]);
        return;
    }
    usz middle=left+(right-left)/2;
    rct_build(g,t,2*node,left,middle); rct_build(g,t,2*node+1,middle,right);
    for (usz child=2*node; child<=2*node+1; child++) {
        rct_edge(g,(usz)t.down[node],(usz)t.down[child]);
        rct_edge(g,(usz)t.up[child],(usz)t.up[node]);
        rct_edge(g,(usz)t.any[child],(usz)t.any[node]);
    }
}
fn void rct_connect(RctGraph* g, RctTrees* t, usz node, usz left, usz right,
                    usz ql, usz qr, long kind, usz target) {
    if (ql<=left && right<=qr) {
        if (kind==1) rct_edge(g,target,(usz)t.down[node]);
        else if (kind==2) rct_edge(g,(usz)t.up[node],target);
        else rct_edge(g,(usz)t.any[node],target);
        return;
    }
    usz middle=left+(right-left)/2;
    if (ql<middle) rct_connect(g,t,2*node,left,middle,ql,qr,kind,target);
    if (qr>middle) rct_connect(g,t,2*node+1,middle,right,ql,qr,kind,target);
}

fn long range_constraint_topological_feasibility(long* input, usz length)
    @export("range_constraint_topological_feasibility") {
    if (input==null || length<2 || input[0]<1 || input[0]>4096 || input[1]<0 || input[1]>8192) return -1;
    usz n=(usz)input[0], m=(usz)input[1];
    if (length!=2+4*m) return -1;
    for (usz i=0; i<m; i++) {
        long kind=input[2+4*i], left=input[3+4*i], right=input[4+4*i], target=input[5+4*i];
        if (kind<1 || kind>3 || left<0 || left>=right || right>(long)n || target<0 || target>=(long)n ||
            (left<=target && target<right)) return -1;
    }
    usz node_cap=7*n+m+1, edge_cap=9*n+32*m+1, tree_cap=4*n;
    usz size=4*node_cap+2*edge_cap+3*tree_cap;
    long* memory=(long*)calloc(size,sizeof(long));
    if (memory==null) return -1;
    RctGraph g={memory,memory+node_cap,memory+2*node_cap,memory+4*node_cap,
                memory+4*node_cap+edge_cap,0,0};
    long* queue=memory+3*node_cap;
    long* tree=memory+4*node_cap+2*edge_cap;
    RctTrees t={tree,tree+tree_cap,tree+2*tree_cap};
    for (usz i=0; i<n; i++) rct_node(&g,false);
    rct_build(&g,&t,1,0,n);
    for (usz i=0; i<m; i++) {
        long kind=input[2+4*i];
        usz left=(usz)input[3+4*i], right=(usz)input[4+4*i], target=(usz)input[5+4*i];
        if (kind==3) {
            usz gate=rct_node(&g,true);
            rct_connect(&g,&t,1,0,n,left,right,kind,gate); rct_edge(&g,gate,target);
        } else rct_connect(&g,&t,1,0,n,left,right,kind,target);
    }
    usz head=0, tail=0, emitted=0;
    for (usz i=0; i<g.nodes; i++) {
        if (g.first[i]!=0) g.degree[i]=1;
        if (g.degree[i]==0) queue[tail++]=(long)i;
    }
    while (head<tail) {
        usz node=(usz)queue[head++];
        if (node<n) emitted++;
        long edge=g.head[node];
        while (edge>=0) {
            usz target=(usz)g.to[(usz)edge];
            if (g.degree[target]>0) {
                g.degree[target]--;
                if (g.degree[target]==0) queue[tail++]=(long)target;
            }
            edge=g.next[(usz)edge];
        }
    }
    free(memory);
    return emitted==n ? 1 : 0;
}
