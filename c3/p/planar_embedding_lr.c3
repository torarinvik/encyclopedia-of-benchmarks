module planar_embedding_lr;

const int MAX_N=32, MAX_M=96, MAX_D=192, INF_LEVEL=1000;
struct Interval { int low; int high; }
struct Conflict { Interval left; Interval right; }
struct State {
    int n,m;
    int[96] eu,ev,tail,head,low,low2,nest,ref,side,low_edge,bottom;
    int[32][32] edge_of,adj,rotation;
    int[32] degree,height,parent,out_count,rotation_count,left_ref,right_ref,roots;
    int[32][32] out;
    Conflict[192] stack;
    int stack_len,root_count;
}

fn Interval empty_interval() { return {-1,-1}; }
fn Conflict empty_conflict() { return {empty_interval(),empty_interval()}; }
fn bool interval_empty(Interval a) { return a.low<0; }
fn void swap_intervals(Conflict* p) { Interval t=p.left; p.left=p.right; p.right=t; }
fn void update_parent(State* s,int back,int pe) {
    if (pe<0) return;
    if (s.low[back]<s.low[pe]) {
        s.low2[pe]=s.low[pe]<s.low2[back] ? s.low[pe] : s.low2[back]; s.low[pe]=s.low[back];
    } else if (s.low[back]>s.low[pe]) {
        if (s.low[back]<s.low2[pe]) s.low2[pe]=s.low[back];
    } else if (s.low2[back]<s.low2[pe]) s.low2[pe]=s.low2[back];
}
fn void orient(State* s,int v) {
    int pe=s.parent[v];
    for (int i=0;i<s.degree[v];i++) {
        int w=s.adj[v][i], e=s.edge_of[v][w];
        if (s.tail[e]>=0) continue;
        s.tail[e]=v; s.head[e]=w; s.low[e]=s.height[v]; s.low2[e]=s.height[v];
        if (s.height[w]<0) {
            s.parent[w]=e; s.height[w]=s.height[v]+1; orient(s,w);
            s.nest[e]=2*s.low[e]+(s.low2[e]<s.height[v] ? 1 : 0);
        } else {
            s.low[e]=s.height[w]; s.low2[e]=s.height[v];
            s.nest[e]=2*s.low[e]+(s.low2[e]<s.height[v] ? 1 : 0);
        }
        update_parent(s,e,pe);
    }
}
fn bool conflicts(State* s,Interval a,int e) { return a.high>=0 && s.low[a.high]>s.low[e]; }
fn int pair_lowest(State* s,Conflict p) {
    int a=p.left.low>=0 ? s.low[p.left.low] : INF_LEVEL;
    int b=p.right.low>=0 ? s.low[p.right.low] : INF_LEVEL;
    return a<b ? a : b;
}
fn bool add_constraints(State* s,int ei,int pe) {
    Conflict p=empty_conflict();
    while (true) {
        if (s.stack_len==0) return false;
        Conflict q=s.stack[s.stack_len-1]; s.stack_len--;
        if (!interval_empty(q.left)) swap_intervals(&q);
        if (!interval_empty(q.left)) return false;
        if (s.low[q.right.low]>s.low[pe]) {
            if (interval_empty(p.right)) p.right=q.right;
            else { s.ref[p.right.low]=q.right.high; p.right.low=q.right.low; }
        } else s.ref[q.right.low]=s.low_edge[pe];
        if (s.stack_len-1==s.bottom[ei]) break;
    }
    while (s.stack_len>0 && (conflicts(s,s.stack[s.stack_len-1].left,ei) || conflicts(s,s.stack[s.stack_len-1].right,ei))) {
        Conflict q=s.stack[s.stack_len-1]; s.stack_len--;
        if (conflicts(s,q.right,ei)) swap_intervals(&q);
        if (conflicts(s,q.right,ei)) return false;
        if (p.right.low>=0) s.ref[p.right.low]=q.right.high;
        if (q.right.low>=0) p.right.low=q.right.low;
        if (interval_empty(p.left)) p.left=q.left;
        else { s.ref[p.left.low]=q.left.high; p.left.low=q.left.low; }
    }
    if (!interval_empty(p.left) || !interval_empty(p.right)) { s.stack[s.stack_len]=p; s.stack_len++; }
    return true;
}
fn void remove_returns(State* s,int e) {
    int u=s.tail[e];
    while (s.stack_len>0 && pair_lowest(s,s.stack[s.stack_len-1])==s.height[u]) {
        Conflict p=s.stack[s.stack_len-1]; s.stack_len--; if (p.left.low>=0) s.side[p.left.low]=-1;
    }
    if (s.stack_len>0) {
        Conflict p=s.stack[s.stack_len-1]; s.stack_len--;
        while (p.left.high>=0 && s.head[p.left.high]==u) p.left.high=s.ref[p.left.high];
        if (p.left.high<0 && p.left.low>=0) { s.ref[p.left.low]=p.right.low; s.side[p.left.low]=-1; p.left.low=-1; }
        while (p.right.high>=0 && s.head[p.right.high]==u) p.right.high=s.ref[p.right.high];
        if (p.right.high<0 && p.right.low>=0) { s.ref[p.right.low]=p.left.low; s.side[p.right.low]=-1; p.right.low=-1; }
        s.stack[s.stack_len]=p; s.stack_len++;
    }
    if (s.low[e]<s.height[u] && s.stack_len>0) {
        Conflict p=s.stack[s.stack_len-1]; int lh=p.left.high,rh=p.right.high;
        s.ref[e]=lh>=0 && (rh<0 || s.low[lh]>s.low[rh]) ? lh : rh;
    }
}
fn bool test_dfs(State* s,int v) {
    int pe=s.parent[v];
    for (int i=0;i<s.out_count[v];i++) {
        int e=s.out[v][i],w=s.head[e]; s.bottom[e]=s.stack_len-1;
        if (s.parent[w]==e) { if (!test_dfs(s,w)) return false; }
        else {
            s.low_edge[e]=e; Conflict p=empty_conflict(); p.right={e,e};
            s.stack[s.stack_len]=p; s.stack_len++;
            if (s.low[e]<s.height[v]) {
                if (i==0) { if (pe>=0) s.low_edge[pe]=s.low_edge[e]; }
                else if (pe<0 || !add_constraints(s,e,pe)) return false;
            }
        }
    }
    if (pe>=0) remove_returns(s,pe);
    return true;
}
fn int resolve_side(State* s,int e) {
    if (s.ref[e]>=0) { int r=s.ref[e]; s.side[e]*=resolve_side(s,r); s.ref[e]=-1; }
    return s.side[e];
}
fn bool edge_before(State* s,int a,int b,int* depth) { return depth[a]<depth[b] || (depth[a]==depth[b] && s.head[a]<s.head[b]); }
fn void insert_neighbor(State* s,int v,int w,int reference,bool after) {
    int count=s.rotation_count[v],pos=0;
    if (count>0 && reference>=0) {
        while (pos<count && s.rotation[v][pos]!=reference) pos++;
        if (pos==count) pos=count; else if (after) pos=(pos+1)%count;
    }
    for (int i=count;i>pos;i--) s.rotation[v][i]=s.rotation[v][i-1];
    s.rotation[v][pos]=w; s.rotation_count[v]=count+1;
}
fn void embed(State* s,int v) {
    for (int i=0;i<s.out_count[v];i++) {
        int e=s.out[v][i],w=s.head[e];
        if (s.parent[w]==e) {
            insert_neighbor(s,w,v,-1,false); s.left_ref[v]=w; s.right_ref[v]=w; embed(s,w);
        } else if (s.side[e]==1) { insert_neighbor(s,w,v,s.right_ref[w],true); }
        else { insert_neighbor(s,w,v,s.left_ref[w],false); s.left_ref[w]=v; }
    }
}

fn long planar_embedding_lr(long* input,usz length,uchar* output,usz capacity) @export("planar_embedding_lr") {
    if (input==null || length<2 || length>195) return -1;
    long n64=input[0],m64=input[1];
    if (n64<1 || n64>MAX_N || m64<0 || m64>MAX_M || length!=(usz)(2+2*m64)) return -1;
    State s={}; s.n=(int)n64; s.m=(int)m64;
    for (int v=0;v<s.n;v++) { s.height[v]=-1; s.parent[v]=-1; s.left_ref[v]=-1; s.right_ref[v]=-1; }
    for (int u=0;u<s.n;u++) for (int v=0;v<s.n;v++) s.edge_of[u][v]=-1;
    for (int e=0;e<s.m;e++) {
        s.tail[e]=-1; s.head[e]=-1; s.ref[e]=-1; s.side[e]=1; s.low_edge[e]=-1; s.bottom[e]=-1;
        long u64=input[2+2*e],v64=input[3+2*e]; if (u64<0 || u64>=v64 || v64>=n64) return -1;
        int u=(int)u64,v=(int)v64; if (s.edge_of[u][v]>=0) return -1;
        s.edge_of[u][v]=e; s.edge_of[v][u]=e;
    }
    for (int v=0;v<s.n;v++) for (int w=0;w<s.n;w++) if (s.edge_of[v][w]>=0) { s.adj[v][s.degree[v]]=w; s.degree[v]++; }
    for (int r=0;r<s.n;r++) if (s.height[r]<0) { s.height[r]=0; s.roots[s.root_count]=r; s.root_count++; orient(&s,r); }
    for (int e=0;e<s.m;e++) { int v=s.tail[e],i=s.out_count[v]; s.out[v][i]=e; s.out_count[v]++; }
    for (int v=0;v<s.n;v++) for (int i=1;i<s.out_count[v];i++) {
        int e=s.out[v][i],j=i; while (j>0 && edge_before(&s,e,s.out[v][j-1],s.nest)) { s.out[v][j]=s.out[v][j-1]; j--; } s.out[v][j]=e;
    }
    bool planar=true; for (int i=0;i<s.root_count;i++) if (!test_dfs(&s,s.roots[i])) { planar=false; break; }
    if (output==null) return -2;
    if (!planar) { if (capacity<1) return -2; output[0]=0; return 1; }
    int[96] depth; for (int e=0;e<s.m;e++) depth[e]=s.nest[e]*resolve_side(&s,e);
    for (int v=0;v<s.n;v++) for (int i=1;i<s.out_count[v];i++) {
        int e=s.out[v][i],j=i; while (j>0 && edge_before(&s,e,s.out[v][j-1],&depth[0])) { s.out[v][j]=s.out[v][j-1]; j--; } s.out[v][j]=e;
    }
    for (int v=0;v<s.n;v++) for (int i=0;i<s.out_count[v];i++) { int k=s.rotation_count[v]++; s.rotation[v][k]=s.head[s.out[v][i]]; }
    for (int i=0;i<s.root_count;i++) embed(&s,s.roots[i]);
    usz needed=(usz)(1+2*s.m); if (capacity<needed) return -2;
    output[0]=1; usz at=1;
    for (int v=0;v<s.n;v++) for (int i=0;i<s.rotation_count[v];i++) { output[at]=(uchar)s.rotation[v][i]; at++; }
    return (long)needed;
}
