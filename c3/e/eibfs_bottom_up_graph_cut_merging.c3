module eibfs_bottom_up_graph_cut_merging;

const int NMAX = 8, MMAX = 24, INPUT_MAX = 77, EVENT_MAX = 100000;
const int FREE_TREE = 0, S_TREE = 1, T_TREE = 2;
struct Eibfs {
    int n; int source; int sink; bool forward;
    int[8] kind; int[8] parent;
    long[64] original; long[64] residual;
    long[8] balance; long[8] ds; long[8] dt; long Ds; long Dt;
    bool[8] orphaned; int events;
}

fn int root(Eibfs* s, int v) {
    for (int i = 0; i < s.n; i++) { if (s.parent[v] < 0) return v; v = s.parent[v]; }
    return -1;
}
fn long bottleneck(Eibfs* s, int v, int kind) {
    long answer = 2401;
    for (int i = 0; i < s.n; i++) {
        int p = s.parent[v]; if (p < 0) return answer;
        long cap = kind == S_TREE ? s.residual[p * NMAX + v] : s.residual[v * NMAX + p];
        if (cap < answer) answer = cap; v = p;
    }
    return 0;
}
fn void push(Eibfs* s, int u, int v, long amount) {
    s.residual[u * NMAX + v] -= amount; s.residual[v * NMAX + u] += amount;
    if (u != s.source && u != s.sink) s.balance[u] -= amount;
    if (v != s.source && v != s.sink) s.balance[v] += amount;
}
fn void mark(Eibfs* s, int v, int* q, int* tail) {
    if (!s.orphaned[v]) { s.orphaned[v] = true; q[*tail] = v; *tail += 1; }
}
fn void detach(Eibfs* s, int v, int kind, int* q, int* tail) {
    for (int c = 0; c < s.n; c++) if (s.kind[c] == kind && s.parent[c] == v) { s.parent[c] = -1; mark(s,c,q,tail); }
}
fn void adopt(Eibfs* s, int v, int kind, int* q, int* tail) {
    bool sink_side = kind == T_TREE;
    s.orphaned[v] = false;
    long old = sink_side ? s.dt[v] : s.ds[v];
    for (int u = 0; u < s.n; u++) {
        long cap = sink_side ? s.residual[v*NMAX+u] : s.residual[u*NMAX+v];
        long label = sink_side ? s.dt[u] : s.ds[u];
        long here = sink_side ? s.dt[v] : s.ds[v];
        if (u != v && s.kind[u] == kind && cap > 0 && here == label + 1) { s.parent[v] = u; return; }
    }
    long frontier = sink_side ? s.Dt : s.Ds;
    bool subtract = sink_side ? s.forward : !s.forward;
    long limit = frontier - (subtract ? 1 : 0), best = 4*s.n;
    for (int u = 0; u < s.n; u++) {
        long cap = sink_side ? s.residual[v*NMAX+u] : s.residual[u*NMAX+v];
        long label = sink_side ? s.dt[u] : s.ds[u];
        if (u != v && s.kind[u] == kind && cap > 0 && label <= limit && label < best) best = label;
    }
    int p = -1;
    for (int u = 0; u < s.n; u++) {
        long cap = sink_side ? s.residual[v*NMAX+u] : s.residual[u*NMAX+v];
        long label = sink_side ? s.dt[u] : s.ds[u];
        if (u != v && s.kind[u] == kind && cap > 0 && label == best) { p=u; break; }
    }
    if (p >= 0 && best + 1 > old) {
        detach(s,v,kind,q,tail); s.parent[v]=p;
        if (sink_side) s.dt[v]=best+1; else s.ds[v]=best+1;
        return;
    }
    detach(s,v,kind,q,tail); s.parent[v]=-1; s.kind[v]=FREE_TREE;
    if (sink_side && s.balance[v] > 0) { s.kind[v]=S_TREE; s.ds[v]=s.Ds+(s.forward?1:0); }
    if (!sink_side && s.balance[v] < 0) { s.kind[v]=T_TREE; s.dt[v]=s.Dt+(s.forward?0:1); }
}
fn void repair_orphans(Eibfs* s, int kind, int* q, int head, int tail) {
    while (head < tail) { int v=q[head++]; s.orphaned[v]=false; if(s.kind[v]==kind) adopt(s,v,kind,q,&tail); }
}
fn void drain(Eibfs* s, int v, int kind) {
    int root_v=root(s,v); if(root_v<0)return;
    int[512] q=zeroed; int head=0,tail=0,x=v;
    while ((kind==T_TREE?s.balance[x]>0:s.balance[x]<0)&&s.parent[x]>=0) {
        int p=s.parent[x]; long cap=kind==T_TREE?s.residual[x*NMAX+p]:s.residual[p*NMAX+x];
        long need=kind==T_TREE?s.balance[x]:-s.balance[x]; long amount=need<cap?need:cap;
        if(amount>0){if(kind==T_TREE)push(s,x,p,amount);else push(s,p,x,amount);}
        long after=kind==T_TREE?s.balance[x]:-s.balance[x]; long rem=kind==T_TREE?s.residual[x*NMAX+p]:s.residual[p*NMAX+x];
        if(rem==0&&after>=0){s.parent[x]=-1;mark(s,x,&q[0],&tail);break;}
        if(after==0)break; x=p;
    }
    if(kind==T_TREE&&root_v!=s.sink&&s.kind[root_v]==kind&&s.balance[root_v]>=0){s.parent[root_v]=-1;mark(s,root_v,&q[0],&tail);}
    if(kind==S_TREE&&root_v!=s.source&&s.kind[root_v]==kind&&s.balance[root_v]<=0){s.parent[root_v]=-1;mark(s,root_v,&q[0],&tail);}
    repair_orphans(s,kind,&q[0],head,tail);
}
fn void repair(Eibfs* s) {
    while(true){
        bool found=false;
        for(int v=0;v<s.n;v++)if(s.kind[v]==T_TREE&&s.balance[v]>0){drain(s,v,T_TREE);found=true;break;}
        if(found)continue;
        for(int v=0;v<s.n;v++)if(s.kind[v]==S_TREE&&s.balance[v]<0){drain(s,v,S_TREE);found=true;break;}
        if(!found)return;
    }
}
fn bool augment(Eibfs* s,int v,int w){
    int rs=root(s,v),rt=root(s,w);if(rs<0||rt<0||s.residual[v*NMAX+w]<=0)return false;
    long c=s.residual[v*NMAX+w],bs=bottleneck(s,v,S_TREE),bt=bottleneck(s,w,T_TREE),amount;
    if(rs==s.source&&rt==s.sink)amount=c;
    else if(rs==s.source)amount=bs<c?bs:c;
    else if(rt==s.sink)amount=c<bt?c:bt;
    else {amount=s.balance[rs];if(bs<amount)amount=bs;if(c<amount)amount=c;if(bt<amount)amount=bt;if(-s.balance[rt]<amount)amount=-s.balance[rt];}
    if(amount<=0)return false;push(s,v,w,amount);repair(s);return true;
}
fn long solve(Eibfs* s){
    for(int phase=0;phase<4*s.n+4;phase++){
        bool finished=false;
        while(true){bool restart=false;
            if(s.forward){
                for(int v=0;v<s.n&&!restart;v++)if(s.kind[v]==S_TREE&&s.ds[v]==s.Ds)
                    for(int w=0;w<s.n;w++)if(s.residual[v*NMAX+w]>0&&s.kind[w]!=S_TREE){
                        if(s.kind[w]==FREE_TREE){s.kind[w]=S_TREE;s.parent[w]=v;s.ds[w]=s.Ds+1;}
                        else if(s.kind[w]==T_TREE&&augment(s,v,w)){if(++s.events>EVENT_MAX)return -1;restart=true;break;}
                    }
                if(!restart){bool next=false;for(int v=0;v<s.n;v++)if(s.kind[v]==S_TREE&&s.ds[v]==s.Ds+1)next=true;
                    if(!next)finished=true;else s.Ds++;break;}
            }else{
                for(int w=0;w<s.n&&!restart;w++)if(s.kind[w]==T_TREE&&s.dt[w]==s.Dt)
                    for(int v=0;v<s.n;v++)if(s.residual[v*NMAX+w]>0&&s.kind[v]!=T_TREE){
                        if(s.kind[v]==FREE_TREE){s.kind[v]=T_TREE;s.parent[v]=w;s.dt[v]=s.Dt+1;}
                        else if(s.kind[v]==S_TREE&&augment(s,v,w)){if(++s.events>EVENT_MAX)return -1;restart=true;break;}
                    }
                if(!restart){bool next=false;for(int v=0;v<s.n;v++)if(s.kind[v]==T_TREE&&s.dt[v]==s.Dt+1)next=true;
                    if(!next)finished=true;else s.Dt++;break;}
            }
        }
        if(finished)break;s.forward=!s.forward;
    }
    bool[8] reachable=zeroed;int[8] queue=zeroed;int head=0,tail=0;
    for(int v=0;v<s.n;v++)if(s.kind[v]==S_TREE){reachable[v]=true;queue[tail++]=v;}
    while(head<tail){int u=queue[head++];for(int v=0;v<s.n;v++)if(s.residual[u*NMAX+v]>0&&!reachable[v]){reachable[v]=true;queue[tail++]=v;}}
    long cut=0;for(int u=0;u<s.n;u++)if(reachable[u])for(int v=0;v<s.n;v++)if(!reachable[v])cut+=s.original[u*NMAX+v];
    return cut;
}

fn long eibfs_maxflow(long* input, usz length) @export("eibfs_maxflow") {
    if(input==null||length<4||length>INPUT_MAX)return -1;
    long nv=input[0],mv=input[1],sv=input[2],tv=input[3];
    if(nv<2||nv>NMAX||mv<0||mv>MMAX||sv<0||sv>=nv||tv<0||tv>=nv||sv==tv||length!=4+3*(usz)mv)return -1;
    Eibfs s={};s.n=(int)nv;s.source=(int)sv;s.sink=(int)tv;s.forward=true;
    for(int v=0;v<s.n;v++)s.parent[v]=-1;
    for(usz e=0;e<(usz)mv;e++){long u=input[4+3*e],v=input[5+3*e],c=input[6+3*e];if(u<0||u>=nv||v<0||v>=nv||u==v||c<0||c>100)return -1;s.original[(int)u*NMAX+(int)v]+=c;s.residual[(int)u*NMAX+(int)v]+=c;}
    s.kind[s.source]=S_TREE;s.kind[s.sink]=T_TREE;
    return solve(&s);
}

const int MERGE_NMAX = 6, MERGE_MMAX = 6, MERGE_INPUT_MAX = 46;
struct MergeEdge { int u; int v; long uv; long vu; }

fn int merge_find(int* parent, int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

fn long merge_component_flow(int n, bool* active, long* source_cap, long* sink_cap,
                             MergeEdge* edges, int m) {
    int[MERGE_NMAX] local = {-1, -1, -1, -1, -1, -1}; int k = 0;
    for (int v = 0; v < n; v++) if (active[v]) local[v] = k++;
    long[4 + 3 * (2 * MERGE_NMAX + 2 * MERGE_MMAX)] frame = zeroed;
    int source = k, sink = k + 1; frame[0] = k + 2; frame[2] = source; frame[3] = sink;
    usz at = 4; int arc_count = 0;
    for (int v = 0; v < n; v++) if (active[v]) {
        frame[at++] = source; frame[at++] = local[v]; frame[at++] = source_cap[v]; arc_count++;
        frame[at++] = local[v]; frame[at++] = sink; frame[at++] = sink_cap[v]; arc_count++;
    }
    for (int e = 0; e < m; e++) if (local[edges[e].u] >= 0 && local[edges[e].v] >= 0) {
        frame[at++] = local[edges[e].u]; frame[at++] = local[edges[e].v]; frame[at++] = edges[e].uv; arc_count++;
        frame[at++] = local[edges[e].v]; frame[at++] = local[edges[e].u]; frame[at++] = edges[e].vu; arc_count++;
    }
    frame[1] = arc_count;
    return eibfs_maxflow(&frame[0], at);
}

fn long eibfs_bottom_up_graph_cut_merging(long* input, usz length) @export("eibfs_bottom_up_graph_cut_merging") {
    if (input == null || length < 3 || length > MERGE_INPUT_MAX) return -1;
    long nv = input[0], mv = input[1], bv = input[2];
    if (nv < 2 || nv > MERGE_NMAX || mv < 0 || mv > MERGE_MMAX || bv < 1 || bv > 4 || bv > nv || length != 3 + 3 * (usz)nv + 4 * (usz)mv) return -1;
    int n = (int)nv, m = (int)mv, blocks = (int)bv;
    int[MERGE_NMAX] block = zeroed; bool[4] seen = zeroed;
    long[MERGE_NMAX] source_cap = zeroed, sink_cap = zeroed;
    for (int v = 0; v < n; v++) { long id = input[3 + v]; if (id < 0 || id >= blocks) return -1; block[v] = (int)id; seen[block[v]] = true; }
    for (int b = 0; b < blocks; b++) if (!seen[b]) return -1;
    for (int v = 0; v < n; v++) { source_cap[v] = input[3 + n + v]; sink_cap[v] = input[3 + 2 * n + v]; if (source_cap[v] < 0 || source_cap[v] > 7 || sink_cap[v] < 0 || sink_cap[v] > 7) return -1; }
    MergeEdge[MERGE_MMAX] edges = zeroed;
    for (int e = 0; e < m; e++) { usz p = (usz)(3 + 3 * n + 4 * e); long u=input[p],v=input[p+1],uv=input[p+2],vu=input[p+3]; if(u<0||u>=n||v<0||v>=n||u==v||uv<0||uv>7||vu<0||vu>7)return -1;edges[e].u=(int)u;edges[e].v=(int)v;edges[e].uv=uv;edges[e].vu=vu; }

    int[MERGE_NMAX] tags = zeroed; long[4] flow = zeroed;
    for (int b = 0; b < blocks; b++) {
        int[MERGE_NMAX] vertices = zeroed; bool[MERGE_NMAX] active = zeroed; int k = 0;
        for(int v=0;v<n;v++)if(block[v]==b){vertices[k++]=v;active[v]=true;}
        long best_cost = 1L << 60; uint best_mask = 0;
        for(uint mask=0;mask<(1u<<k);mask++){long cost=0;
            for(int i=0;i<k;i++){int v=vertices[i];cost+=(mask&(1u<<i))!=0?sink_cap[v]:source_cap[v];}
            for(int e=0;e<m;e++)if(block[edges[e].u]==b&&block[edges[e].v]==b){int iu=0,iv=0;while(vertices[iu]!=edges[e].u)iu++;while(vertices[iv]!=edges[e].v)iv++;bool us=(mask&(1u<<iu))!=0,vs=(mask&(1u<<iv))!=0;if(us&&!vs)cost+=edges[e].uv;else if(vs&&!us)cost+=edges[e].vu;}
            if(cost<best_cost||(cost==best_cost&&mask<best_mask)){best_cost=cost;best_mask=mask;}}
        for(int i=0;i<k;i++)tags[vertices[i]]=(best_mask&(1u<<i))!=0?1:2;
        flow[b]=merge_component_flow(n,&active[0],&source_cap[0],&sink_cap[0],&edges[0],m);if(flow[b]<0)return -1;
    }
    int[16] score=zeroed,has=zeroed;
    for(int e=0;e<m;e++)if(block[edges[e].u]!=block[edges[e].v]&&(edges[e].uv||edges[e].vu)){int a=block[edges[e].u],b=block[edges[e].v];if(a>b){int t=a;a=b;b=t;}has[a*4+b]=1;if(tags[edges[e].u]!=tags[edges[e].v])score[a*4+b]+=(edges[e].uv>0)+(edges[e].vu>0);}
    int[6] pair_a=zeroed,pair_b=zeroed,pair_score=zeroed;int pair_count=0;
    for(int a=0;a<blocks;a++)for(int b=a+1;b<blocks;b++)if(has[a*4+b]){int pos=pair_count++;while(pos>0&&(pair_score[pos-1]<score[a*4+b]||(pair_score[pos-1]==score[a*4+b]&&(pair_a[pos-1]>a||(pair_a[pos-1]==a&&pair_b[pos-1]>b))))){pair_a[pos]=pair_a[pos-1];pair_b[pos]=pair_b[pos-1];pair_score[pos]=pair_score[pos-1];pos--;}pair_a[pos]=a;pair_b[pos]=b;pair_score[pos]=score[a*4+b];}
    int[4] parent={0,1,2,3};
    for(int i=0;i<pair_count;i++){int a=merge_find(&parent[0],pair_a[i]),b=merge_find(&parent[0],pair_b[i]);if(a==b)continue;int root=a<b?a:b,other=a<b?b:a;parent[other]=root;bool[MERGE_NMAX] active=zeroed;for(int v=0;v<n;v++)active[v]=merge_find(&parent[0],block[v])==root;flow[root]=merge_component_flow(n,&active[0],&source_cap[0],&sink_cap[0],&edges[0],m);if(flow[root]<0)return -1;flow[other]=0;}
    long answer=0;for(int b=0;b<blocks;b++)if(merge_find(&parent[0],b)==b)answer+=flow[b];return answer;
}
