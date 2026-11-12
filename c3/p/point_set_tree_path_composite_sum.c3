module point_set_tree_path_composite_sum;

const int PTS_MAX_N = 16, PTS_MAX_Q = 32, PTS_MAX_E = 15;
const int PTS_MAX_CLUSTERS = 75, PTS_MAX_INPUT = 238;
const long PTS_MOD = 998244353;
enum { PTS_VERTEX = 0, PTS_EDGE = 1, PTS_RAKE = 2,
       PTS_BRANCH = 3, PTS_ATTACH = 4, PTS_COMPRESS = 5 }

struct PtsAffine { long mul, add; }
struct PtsCluster {
    short kind, a, b, parent, shared, boundary0, boundary1, boundary_count, edge_id;
    uint8 has0, has1;
    uint16 mask;
    int count;
    long sum0, sum1;
    PtsAffine forward, reverse;
}
struct PtsContext { long sum0, count0, sum1, count1; }

fn long pts_mod(long x) { x %= PTS_MOD; if (x < 0) x += PTS_MOD; return x; }
fn PtsAffine pts_identity() { return PtsAffine{1, 0}; }
fn PtsAffine pts_compose(PtsAffine outer, PtsAffine inner) {
    return PtsAffine{outer.mul * inner.mul % PTS_MOD,
                     (outer.mul * inner.add + outer.add) % PTS_MOD};
}
fn long pts_apply(PtsAffine map, long sum, long count) {
    return (map.mul * sum + map.add * count) % PTS_MOD;
}
fn int pts_boundary_index(PtsCluster* node, int vertex) {
    if (node.boundary0 == vertex) return 0;
    if (node.boundary_count == 2 && node.boundary1 == vertex) return 1;
    return -1;
}
fn bool pts_has(PtsCluster* node, int vertex) {
    int index = pts_boundary_index(node, vertex);
    if (index == 0) return node.has0 != 0;
    if (index == 1) return node.has1 != 0;
    return false;
}
fn long pts_sum_at(PtsCluster* node, int vertex) {
    return pts_boundary_index(node, vertex) == 0 ? node.sum0 : node.sum1;
}
fn PtsAffine pts_map_at(PtsCluster* node, int from, int to) {
    if (from == to || node.boundary_count != 2) return pts_identity();
    return node.boundary0 == from && node.boundary1 == to ? node.forward : node.reverse;
}

fn void pts_recalculate(PtsCluster* nodes, int id, long* values, PtsAffine* edge_map) {
    PtsCluster* p = &nodes[id];
    if (p.kind == PTS_VERTEX) {
        p.count = 1; p.mask = (uint16)(1 << p.boundary0);
        p.sum0 = values[p.boundary0]; p.has0 = 1;
        return;
    }
    if (p.kind == PTS_EDGE) { p.forward = p.reverse = edge_map[p.edge_id]; return; }
    PtsCluster* a = &nodes[p.a]; PtsCluster* b = &nodes[p.b];
    int x = p.shared;
    bool overlap = pts_has(a, x) && pts_has(b, x);
    int removed = overlap ? 1 : 0;
    long duplicate = overlap ? values[x] : 0;
    p.count = a.count + b.count - removed;
    p.mask = a.mask | b.mask;
    int[2] boundaries = {p.boundary0, p.boundary1};
    for (int index = 0; index < p.boundary_count; index += 1) {
        int boundary = boundaries[index]; long total;
        if (boundary == x) total = pts_mod(pts_sum_at(a, x) + pts_sum_at(b, x) - duplicate);
        else if (pts_boundary_index(a, boundary) >= 0) {
            long sibling_sum = pts_mod(pts_sum_at(b, x) - duplicate);
            total = (pts_sum_at(a, boundary) + pts_apply(pts_map_at(a, boundary, x), sibling_sum, b.count - removed)) % PTS_MOD;
        } else {
            long sibling_sum = pts_mod(pts_sum_at(a, x) - duplicate);
            total = (pts_sum_at(b, boundary) + pts_apply(pts_map_at(b, boundary, x), sibling_sum, a.count - removed)) % PTS_MOD;
        }
        bool boundary_has = pts_has(a, boundary) || pts_has(b, boundary);
        if (index == 0) { p.sum0 = total; p.has0 = boundary_has ? 1 : 0; }
        else { p.sum1 = total; p.has1 = boundary_has ? 1 : 0; }
    }
    if (p.boundary_count == 2) {
        int u = p.boundary0, v = p.boundary1;
        bool au = pts_boundary_index(a, u) >= 0, av = pts_boundary_index(a, v) >= 0;
        bool bu = pts_boundary_index(b, u) >= 0, bv = pts_boundary_index(b, v) >= 0;
        if (au && av) { p.forward = pts_map_at(a, u, v); p.reverse = pts_map_at(a, v, u); }
        else if (bu && bv) { p.forward = pts_map_at(b, u, v); p.reverse = pts_map_at(b, v, u); }
        else {
            p.forward = pts_compose(pts_map_at(a, u, x), pts_map_at(b, x, v));
            p.reverse = pts_compose(pts_map_at(b, v, x), pts_map_at(a, x, u));
        }
    }
}

fn int pts_append(PtsCluster* nodes, int* used, int kind, int a_id, int b_id, int shared,
                  long* values, PtsAffine* edge_map) {
    if (used[0] >= PTS_MAX_CLUSTERS) return -1;
    int id = used[0]; used[0] += 1;
    PtsCluster* node = &nodes[id]; *node = PtsCluster{0};
    node.kind = (short)kind; node.a = (short)a_id; node.b = (short)b_id;
    node.parent = -1; node.shared = (short)shared; node.edge_id = -1;
    node.forward = pts_identity(); node.reverse = pts_identity();
    if (kind == PTS_VERTEX) { node.boundary0 = (short)shared; node.boundary_count = 1; }
    else if (kind == PTS_EDGE) {
        node.boundary0 = (short)a_id; node.boundary1 = (short)b_id;
        node.boundary_count = 2; node.edge_id = (short)shared;
    } else {
        PtsCluster* a = &nodes[a_id]; PtsCluster* b = &nodes[b_id];
        int ao = a.boundary_count == 2 && a.boundary0 == shared ? a.boundary1 : a.boundary0;
        int bo = b.boundary_count == 2 && b.boundary0 == shared ? b.boundary1 : b.boundary0;
        if (kind == PTS_RAKE) { node.boundary0 = (short)shared; node.boundary_count = 1; }
        else if (kind == PTS_BRANCH) { node.boundary0 = (short)ao; node.boundary_count = 1; }
        else if (kind == PTS_ATTACH) { node.boundary0 = a.boundary0; node.boundary1 = a.boundary1; node.boundary_count = 2; }
        else { node.boundary0 = (short)ao; node.boundary1 = (short)bo; node.boundary_count = 2; }
        a.parent = (short)id; b.parent = (short)id;
    }
    pts_recalculate(nodes, id, values, edge_map);
    return id;
}

fn int pts_make_rake(PtsCluster* nodes, int* used, int base, int* branches,
                     int branch_count, long* values, PtsAffine* edge_map) {
    int[PTS_MAX_N+1] level; int[PTS_MAX_N+1] next;
    int count = 1; level[0] = base;
    for (int i = 0; i < branch_count; i += 1) { level[count] = branches[i]; count += 1; }
    while (count > 1) {
        int next_count = 0;
        for (int i = 0; i < count; i += 2) {
            if (i + 1 == count) { next[next_count] = level[i]; next_count += 1; }
            else {
                int merged = pts_append(nodes, used, PTS_RAKE, level[i], level[i+1], nodes[level[i]].boundary0, values, edge_map);
                if (merged < 0) return -1;
                next[next_count] = merged; next_count += 1;
            }
        }
        for (int i = 0; i < next_count; i += 1) level[i] = next[i];
        count = next_count;
    }
    return level[0];
}
fn int pts_neighbor_count(bool* adjacency, bool* active, int n, int vertex, int* output) {
    int count = 0;
    for (int other = 0; other < n; other += 1) if (active[other] && adjacency[vertex*PTS_MAX_N+other]) {
        if (count < 2) output[count] = other; count += 1;
    }
    return count;
}
fn int pts_find(usz* parent, int vertex) {
    usz v = (usz)vertex;
    while (parent[v] != v) { parent[v] = parent[parent[v]]; v = parent[v]; }
    return (int)v;
}
fn void pts_context_at(PtsCluster* parent, PtsContext context, int vertex, long* out) {
    int index = pts_boundary_index(parent, vertex);
    out[0] = index == 0 ? context.sum0 : index == 1 ? context.sum1 : 0;
    out[1] = index == 0 ? context.count0 : index == 1 ? context.count1 : 0;
}
fn PtsContext pts_child_context(PtsCluster* nodes, int parent_id, int child_id,
                                PtsContext context, long* values) {
    PtsCluster* parent = &nodes[parent_id]; PtsCluster* child = &nodes[child_id];
    int sibling_id = child_id == parent.a ? parent.b : parent.a;
    PtsCluster* sibling = &nodes[sibling_id]; int x = parent.shared;
    bool overlap = pts_has(child, x) && pts_has(sibling, x);
    long count_x = sibling.count - (overlap ? 1 : 0);
    long sum_x = pts_mod(pts_sum_at(sibling, x) - (overlap ? values[x] : 0));
    int[2] sb = {sibling.boundary0, sibling.boundary1};
    for (int i = 0; i < sibling.boundary_count; i += 1) {
        int boundary = sb[i]; if (pts_boundary_index(parent, boundary) < 0) continue;
        long[2] outside; pts_context_at(parent, context, boundary, &outside[0]);
        sum_x = (sum_x + pts_apply(pts_map_at(sibling, x, boundary), outside[0], outside[1])) % PTS_MOD;
        count_x += outside[1];
    }
    PtsContext result = {0}; int[2] cb = {child.boundary0, child.boundary1};
    for (int i = 0; i < child.boundary_count; i += 1) {
        int boundary = cb[i]; long sum, count;
        if (boundary == x) { sum = sum_x; count = count_x; }
        else { sum = pts_apply(pts_map_at(child, boundary, x), sum_x, count_x); count = count_x; }
        if (boundary != x && pts_boundary_index(parent, boundary) >= 0) {
            long[2] outside; pts_context_at(parent, context, boundary, &outside[0]);
            sum = (sum + outside[0]) % PTS_MOD; count += outside[1];
        }
        if (i == 0) { result.sum0 = sum; result.count0 = count; }
        else { result.sum1 = sum; result.count1 = count; }
    }
    return result;
}
fn long pts_query(PtsCluster* nodes, int root, int* vertex_leaf, int vertex, long* values) {
    int[PTS_MAX_CLUSTERS] path; int len = 1; path[0] = vertex_leaf[vertex];
    while (path[len-1] != root && len < PTS_MAX_CLUSTERS) {
        int parent = nodes[path[len-1]].parent; if (parent < 0) return -1;
        path[len] = parent; len += 1;
    }
    if (path[len-1] != root) return -1;
    PtsContext context = {0};
    for (int i = len-1; i > 0; i -= 1) context = pts_child_context(nodes, path[i], path[i-1], context, values);
    return (nodes[vertex_leaf[vertex]].sum0 + context.sum0) % PTS_MOD;
}
fn void pts_store(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) output[offset+i] = (uint8)((bits >> (8*i)) & 255);
}

fn long point_set_tree_path_composite_sum(long* input, usz length, uint8* output, usz capacity)
    @export("point_set_tree_path_composite_sum") {
    if (input == null || length < 2 || length > PTS_MAX_INPUT) return -1;
    long nr = input[0], qr = input[1];
    if (nr < 1 || nr > PTS_MAX_N || qr < 1 || qr > PTS_MAX_Q) return -1;
    int n = (int)nr, q = (int)qr; usz cursor = 2;
    long[PTS_MAX_N] values = zeroed;
    for (int v = 0; v < n; v += 1) {
        if (cursor >= length) return -1;
        values[v] = input[cursor]; cursor += 1;
        if (values[v] < 0 || values[v] >= PTS_MOD) return -1;
    }
    int[PTS_MAX_E] edge_u = zeroed, edge_v = zeroed;
    PtsAffine[PTS_MAX_E] edge_map = zeroed;
    usz[PTS_MAX_N] dsu = zeroed; for (int v = 0; v < n; v += 1) dsu[v] = (usz)v;
    for (int e = 0; e < n-1; e += 1) {
        if (cursor + 4 > length) return -1;
        long ur=input[cursor], vr=input[cursor+1], mul=input[cursor+2], add=input[cursor+3]; cursor += 4;
        if (ur < 0 || ur >= nr || vr < 0 || vr >= nr || ur == vr || mul < 1 || mul >= PTS_MOD || add < 0 || add >= PTS_MOD) return -1;
        int u=(int)ur, v=(int)vr, ru=pts_find(&dsu[0],u), rv=pts_find(&dsu[0],v);
        if (ru == rv) return -1;
        dsu[ru]=(usz)rv; edge_u[e]=u; edge_v[e]=v; edge_map[e]=PtsAffine{mul,add};
    }
    int tree_root=pts_find(&dsu[0],0); for (int v=1;v<n;v+=1) if(pts_find(&dsu[0],v)!=tree_root)return -1;
    int[PTS_MAX_Q] op_code=zeroed, op_item=zeroed, op_root=zeroed;
    long[PTS_MAX_Q] op_first=zeroed, op_second=zeroed;
    for (int i=0;i<q;i+=1) {
        if(cursor>=length)return -1;
        long opcode=input[cursor];cursor+=1;
        if(opcode==0){
            if(cursor+3>length)return -1;
            long item=input[cursor],value=input[cursor+1],root=input[cursor+2];cursor+=3;
            if(item<0||item>=nr||value<0||value>=PTS_MOD||root<0||root>=nr)return -1;
            op_code[i]=0;op_item[i]=(int)item;op_first[i]=value;op_root[i]=(int)root;
        }else if(opcode==1){
            if(cursor+4>length)return -1;
            long item=input[cursor],mul=input[cursor+1],add=input[cursor+2],root=input[cursor+3];cursor+=4;
            if(item<0||item>=nr-1||mul<1||mul>=PTS_MOD||add<0||add>=PTS_MOD||root<0||root>=nr)return -1;
            op_code[i]=1;op_item[i]=(int)item;op_first[i]=mul;op_second[i]=add;op_root[i]=(int)root;
        }else return -1;
    }
    if(cursor!=length)return -1;
    usz required=8*(usz)q;if(output==null||capacity<required)return -2;
    PtsCluster[PTS_MAX_CLUSTERS] nodes=zeroed;int used=0;
    int[PTS_MAX_N] vertex_leaf=zeroed;int[PTS_MAX_E] edge_leaf=zeroed;
    for(int v=0;v<n;v+=1){int id=pts_append(&nodes[0],&used,PTS_VERTEX,-1,-1,v,&values[0],&edge_map[0]);if(id<0)return -1;vertex_leaf[v]=id;}
    bool[PTS_MAX_N][PTS_MAX_N] adjacency=zeroed;int[PTS_MAX_N][PTS_MAX_N] edge_cluster=zeroed;
    for(int u=0;u<PTS_MAX_N;u+=1)for(int v=0;v<PTS_MAX_N;v+=1)edge_cluster[u][v]=-1;
    for(int e=0;e<n-1;e+=1){int id=pts_append(&nodes[0],&used,PTS_EDGE,edge_u[e],edge_v[e],e,&values[0],&edge_map[0]);if(id<0)return -1;edge_leaf[e]=id;adjacency[edge_u[e]][edge_v[e]]=true;adjacency[edge_v[e]][edge_u[e]]=true;edge_cluster[edge_u[e]][edge_v[e]]=id;edge_cluster[edge_v[e]][edge_u[e]]=id;}
    bool[PTS_MAX_N] active=zeroed;int[PTS_MAX_N][PTS_MAX_N] branches=zeroed;int[PTS_MAX_N] branch_count=zeroed;
    for(int v=0;v<n;v+=1)active[v]=true;
    int active_count=n;
    while(active_count>1){
        if(active_count==2){
            int[2] pair;int found=0;for(int v=0;v<n;v+=1)if(active[v]){pair[found]=v;found+=1;}
            int x=pair[0],y=pair[1];int local=pts_make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x][0],branch_count[x],&values[0],&edge_map[0]);if(local<0)return -1;
            int branch=pts_append(&nodes[0],&used,PTS_BRANCH,edge_cluster[x][y],local,x,&values[0],&edge_map[0]);if(branch<0||branch_count[y]>=PTS_MAX_N)return -1;branches[y][branch_count[y]]=branch;branch_count[y]+=1;
            adjacency[x][y]=false;adjacency[y][x]=false;edge_cluster[x][y]=-1;edge_cluster[y][x]=-1;active[x]=false;active_count-=1;break;
        }
        int[PTS_MAX_N] leaves;int[PTS_MAX_N] leaf_neighbor;int leaf_count=0;
        for(int v=0;v<n;v+=1)if(active[v]){int[2] adjacent; if(pts_neighbor_count(&adjacency[0][0],&active[0],n,v,&adjacent[0])==1){leaves[leaf_count]=v;leaf_neighbor[leaf_count]=adjacent[0];leaf_count+=1;}}
        for(int i=0;i<leaf_count;i+=1){int x=leaves[i],y=leaf_neighbor[i];int local=pts_make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x][0],branch_count[x],&values[0],&edge_map[0]);if(local<0)return -1;int branch=pts_append(&nodes[0],&used,PTS_BRANCH,edge_cluster[x][y],local,x,&values[0],&edge_map[0]);if(branch<0||branch_count[y]>=PTS_MAX_N)return -1;branches[y][branch_count[y]]=branch;branch_count[y]+=1;}
        for(int i=0;i<leaf_count;i+=1){int x=leaves[i],y=leaf_neighbor[i];adjacency[x][y]=false;adjacency[y][x]=false;edge_cluster[x][y]=-1;edge_cluster[y][x]=-1;active[x]=false;active_count-=1;}
        if(active_count<=1)break;
        bool[PTS_MAX_N] chosen=zeroed;int[PTS_MAX_N] compress=zeroed;int cc=0;
        for(int x=0;x<n;x+=1)if(active[x]){int[2] adjacent;if(pts_neighbor_count(&adjacency[0][0],&active[0],n,x,&adjacent[0])!=2)continue;if(!chosen[adjacent[0]]&&!chosen[adjacent[1]]){chosen[x]=true;compress[cc]=x;cc+=1;}}
        int[PTS_MAX_N] px,py,pz,pc;
        for(int i=0;i<cc;i+=1){int x=compress[i],adjacent[2];_=pts_neighbor_count(&adjacency[0][0],&active[0],n,x,&adjacent[0]);int y=adjacent[0],z=adjacent[1];int local=pts_make_rake(&nodes[0],&used,vertex_leaf[x],&branches[x][0],branch_count[x],&values[0],&edge_map[0]);if(local<0)return -1;int attached=pts_append(&nodes[0],&used,PTS_ATTACH,edge_cluster[y][x],local,x,&values[0],&edge_map[0]);if(attached<0)return -1;int merged=pts_append(&nodes[0],&used,PTS_COMPRESS,attached,edge_cluster[x][z],x,&values[0],&edge_map[0]);if(merged<0)return -1;px[i]=x;py[i]=y;pz[i]=z;pc[i]=merged;}
        for(int i=0;i<cc;i+=1){int x=px[i],y=py[i],z=pz[i];adjacency[y][x]=false;adjacency[x][y]=false;adjacency[x][z]=false;adjacency[z][x]=false;edge_cluster[y][x]=-1;edge_cluster[x][y]=-1;edge_cluster[x][z]=-1;edge_cluster[z][x]=-1;active[x]=false;active_count-=1;}
        for(int i=0;i<cc;i+=1){int y=py[i],z=pz[i];adjacency[y][z]=true;adjacency[z][y]=true;edge_cluster[y][z]=pc[i];edge_cluster[z][y]=pc[i];}
    }
    int root_vertex=0;while(!active[root_vertex])root_vertex+=1;
    int root=pts_make_rake(&nodes[0],&used,vertex_leaf[root_vertex],&branches[root_vertex][0],branch_count[root_vertex],&values[0],&edge_map[0]);if(root<0)return -1;
    long[PTS_MAX_Q] answers=zeroed;
    for(int i=0;i<q;i+=1){int item=op_item[i],node_id;if(op_code[i]==0){values[item]=op_first[i];node_id=vertex_leaf[item];pts_recalculate(&nodes[0],node_id,&values[0],&edge_map[0]);}else{edge_map[item]=PtsAffine{op_first[i],op_second[i]};node_id=edge_leaf[item];pts_recalculate(&nodes[0],node_id,&values[0],&edge_map[0]);}int ancestor=nodes[node_id].parent;while(ancestor>=0){pts_recalculate(&nodes[0],ancestor,&values[0],&edge_map[0]);ancestor=nodes[ancestor].parent;}answers[i]=pts_query(&nodes[0],root,&vertex_leaf[0],op_root[i],&values[0]);if(answers[i]<0)return -1;}
    for(int i=0;i<q;i+=1)pts_store(output,8*(usz)i,answers[i]);
    return (long)required;
}
