module fakcharoenphol_rao_planar_sssp;

const int MAX_N = 12;
const int MAX_M = 60;
const int MAX_P = 119;
const int MAX_B = 12;
const int MAX_BASE_ARCS = 3;
const int MAX_BLOCKS = 44;
const usz MAX_INPUT = 2088;
const long INF = 1152921504606846976L;

struct Arc { int tail; int head; long weight; }
struct Piece { int left; int right; int boundary_count; ulong arc_mask; uint vertex_mask; int[MAX_B] boundary; }
struct Block {
    int child; int row_count; int column_count;
    int[MAX_B] rows; int[MAX_B] columns;
    long[MAX_B][MAX_B] weights;
    long[MAX_B] best_value; int[MAX_B] best_row;
}
struct Context {
    int n; int m; int source; int piece_count;
    Piece[MAX_P] pieces; Arc[MAX_M] arcs;
    long[MAX_P][MAX_N][MAX_N] ddg;
    long[MAX_P][MAX_N] potential;
}

fn int popcount(uint value) {
    int result = 0;
    while (value != 0) { result += (int)(value & 1); value >>= 1; }
    return result;
}
fn int popcount64(ulong value) {
    int result = 0;
    while (value != 0) { result += (int)(value & 1UL); value >>= 1; }
    return result;
}

fn uint vertex_mask(Context* ctx, ulong mask) {
    uint result = 0;
    for (int e = 0; e < ctx.m; e++) if ((mask & (1UL << e)) != 0) {
        result |= 1U << ctx.arcs[e].tail; result |= 1U << ctx.arcs[e].head;
    }
    return result;
}

fn bool connected(Context* ctx, ulong mask, uint vertices) {
    if (vertices == 0) return false;
    int start = 0; while ((vertices & (1U << start)) == 0) start++;
    uint reached = 1U << start; bool changed = true;
    while (changed) {
        changed = false;
        for (int e = 0; e < ctx.m; e++) {
            if ((mask & (1UL << e)) == 0) continue;
            int u = ctx.arcs[e].tail, v = ctx.arcs[e].head;
            if ((reached & (1U << u)) != 0 && (reached & (1U << v)) == 0) { reached |= 1U << v; changed = true; }
            if ((reached & (1U << v)) != 0 && (reached & (1U << u)) == 0) { reached |= 1U << u; changed = true; }
        }
    }
    return reached == vertices;
}

fn bool parse(Context* ctx, long* input, usz length) {
    if (input == null || length < 4 || length > MAX_INPUT) return false;
    if (input[0] < 2 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M ||
        input[2] < 0 || input[2] >= input[0] || input[3] < 1 || input[3] > MAX_P || input[3] % 2 == 0) return false;
    ctx.n = (int)input[0]; ctx.m = (int)input[1]; ctx.source = (int)input[2]; ctx.piece_count = (int)input[3];
    bool[MAX_N][MAX_N] seen_arc = {}; bool[MAX_N][MAX_N] seen_pair = {};
    int pair_count = 0; usz offset = 4;
    for (int e = 0; e < ctx.m; e++) {
        if (offset + 3 > length) return false;
        long u0 = input[offset], v0 = input[offset + 1], weight = input[offset + 2]; offset += 3;
        if (u0 < 0 || u0 >= ctx.n || v0 < 0 || v0 >= ctx.n || u0 == v0 || weight < -100 || weight > 100) return false;
        int u = (int)u0, v = (int)v0;
        if (seen_arc[u][v]) return false;
        seen_arc[u][v] = true;
        if (!seen_pair[u][v]) { seen_pair[u][v] = true; seen_pair[v][u] = true; pair_count++; }
        ctx.arcs[e] = {u, v, weight};
    }
    int edge_limit = ctx.n == 2 ? 1 : 3 * ctx.n - 6;
    if (pair_count > edge_limit || ctx.m > 2 * edge_limit) return false;
    bool[MAX_N] reached = {}; int[MAX_N] queue = {}; int head = 0, tail = 0;
    reached[0] = true; queue[tail++] = 0;
    while (head < tail) {
        int u = queue[head++];
        for (int e = 0; e < ctx.m; e++) {
            int v = -1;
            if (ctx.arcs[e].tail == u) v = ctx.arcs[e].head;
            else if (ctx.arcs[e].head == u) v = ctx.arcs[e].tail;
            if (v >= 0 && !reached[v]) { reached[v] = true; queue[tail++] = v; }
        }
    }
    for (int v = 0; v < ctx.n; v++) if (!reached[v]) return false;

    int[MAX_P] parents = {}; ulong leaf_union = 0; int leaf_count = 0;
    ulong full = (1UL << ctx.m) - 1;
    for (int index = 0; index < ctx.piece_count; index++) {
        if (offset + 4 > length) return false;
        long left = input[offset], right = input[offset + 1], mask_value = input[offset + 2], bc0 = input[offset + 3]; offset += 4;
        if (bc0 < 1 || bc0 > ctx.n || bc0 > MAX_B || offset + (usz)bc0 > length) return false;
        Piece piece = {}; piece.left = (int)left; piece.right = (int)right; piece.boundary_count = (int)bc0;
        uint listed = 0;
        for (int j = 0; j < piece.boundary_count; j++) {
            long v0 = input[offset++]; if (v0 < 0 || v0 >= ctx.n) return false;
            int v = (int)v0; uint bit = 1U << v; if ((listed & bit) != 0) return false;
            listed |= bit; piece.boundary[j] = v;
        }
        if (left == -1 && right == -1) {
            if (mask_value <= 0) return false;
            piece.arc_mask = (ulong)mask_value;
            if ((piece.arc_mask & ~full) != 0 || popcount64(piece.arc_mask) > 3 || (leaf_union & piece.arc_mask) != 0) return false;
            leaf_union |= piece.arc_mask; leaf_count++;
            piece.vertex_mask = vertex_mask(ctx, piece.arc_mask);
            if (!connected(ctx, piece.arc_mask, piece.vertex_mask)) return false;
        } else {
            if (left < 0 || right < 0 || left >= index || right >= index || left == right || mask_value != -1) return false;
            int li = (int)left, ri = (int)right;
            if (parents[li] != 0 || parents[ri] != 0) return false;
            parents[li] = 1; parents[ri] = 1;
            Piece lp = ctx.pieces[li], rp = ctx.pieces[ri];
            if ((lp.arc_mask & rp.arc_mask) != 0) return false;
            piece.arc_mask = lp.arc_mask | rp.arc_mask; piece.vertex_mask = lp.vertex_mask | rp.vertex_mask;
            int psize = popcount(piece.vertex_mask), limit = (2 * psize + 2) / 3;
            if (popcount(lp.vertex_mask) > limit || popcount(rp.vertex_mask) > limit || (lp.vertex_mask & rp.vertex_mask) == 0) return false;
        }
        uint expected = 0;
        for (int v = 0; v < ctx.n; v++) {
            uint bit = 1U << v; if ((piece.vertex_mask & bit) == 0) continue;
            if (v == ctx.source) { expected |= bit; continue; }
            for (int e = 0; e < ctx.m; e++) if ((piece.arc_mask & (1UL << e)) == 0 && (ctx.arcs[e].tail == v || ctx.arcs[e].head == v)) { expected |= bit; break; }
        }
        if (listed != expected || !connected(ctx, piece.arc_mask, piece.vertex_mask)) return false;
        if (index == ctx.piece_count - 1 && (piece.arc_mask != full || piece.vertex_mask != (1U << ctx.n) - 1)) return false;
        ctx.pieces[index] = piece;
    }
    if (offset != length || ctx.piece_count != 2 * leaf_count - 1 || leaf_union != full || parents[ctx.piece_count - 1] != 0) return false;
    for (int i = 0; i < ctx.piece_count - 1; i++) if (parents[i] != 1) return false;
    Piece root = ctx.pieces[ctx.piece_count - 1];
    return root.boundary_count == 1 && root.boundary[0] == ctx.source;
}

fn bool bellman(Context* ctx, int* nodes, int node_count, Arc* arcs, int arc_count, long* labels) {
    for (int v = 0; v < ctx.n; v++) labels[v] = INF;
    for (int i = 0; i < node_count; i++) labels[nodes[i]] = 0;
    for (int pass = 0; pass + 1 < node_count; pass++) {
        bool changed = false;
        for (int e = 0; e < arc_count; e++) { Arc a = arcs[e]; if (labels[a.tail] + a.weight < labels[a.head]) { labels[a.head] = labels[a.tail] + a.weight; changed = true; } }
        if (!changed) break;
    }
    for (int e = 0; e < arc_count; e++) { Arc a = arcs[e]; if (labels[a.tail] + a.weight < labels[a.head]) return false; }
    return true;
}

fn bool seeded(Context* ctx, Arc* arcs, int arc_count, long* seeds, long* labels) {
    for (int v = 0; v < ctx.n; v++) labels[v] = seeds[v];
    for (int pass = 0; pass + 1 < ctx.n; pass++) {
        bool changed = false;
        for (int e = 0; e < arc_count; e++) { Arc a = arcs[e]; if (labels[a.tail] != INF && labels[a.tail] + a.weight < labels[a.head]) { labels[a.head] = labels[a.tail] + a.weight; changed = true; } }
        if (!changed) break;
    }
    for (int e = 0; e < arc_count; e++) { Arc a = arcs[e]; if (labels[a.tail] != INF && labels[a.tail] + a.weight < labels[a.head]) return false; }
    return true;
}

fn long monge_sum(long a, long b) { return a == INF || b == INF ? INF : a + b; }
fn bool check_monge(Context* ctx, int index, int lo, int hi) {
    if (hi - lo <= 1) return true;
    Piece piece = ctx.pieces[index]; int middle = (lo + hi) / 2;
    for (int direction = 0; direction < 2; direction++) {
        int rlo = direction == 0 ? lo : middle, rhi = direction == 0 ? middle : hi;
        int clo = direction == 0 ? middle : lo, chi = direction == 0 ? hi : middle;
        for (int i = rlo; i < rhi; i++) for (int i2 = i + 1; i2 < rhi; i2++)
        for (int j = clo; j < chi; j++) for (int j2 = j + 1; j2 < chi; j2++) {
            int u=piece.boundary[i], u2=piece.boundary[i2], v=piece.boundary[j], v2=piece.boundary[j2];
            long lhs=monge_sum(ctx.ddg[index][u][v],ctx.ddg[index][u2][v2]);
            long rhs=monge_sum(ctx.ddg[index][u][v2],ctx.ddg[index][u2][v]);
            if (lhs > rhs) return false;
        }
    }
    return check_monge(ctx,index,lo,middle) && check_monge(ctx,index,middle,hi);
}

fn void add_block(Context* ctx,int child,int* rows,int row_count,int* cols,int col_count,long* potential,Block* blocks,int* count) {
    if (row_count == 0 || col_count == 0 || *count >= MAX_BLOCKS) return;
    Block* b = &blocks[*count]; *count += 1; b.child=child; b.row_count=row_count; b.column_count=col_count;
    for (int i=0;i<row_count;i++) b.rows[i]=rows[i]; for(int j=0;j<col_count;j++) b.columns[j]=cols[j];
    for(int i=0;i<row_count;i++)for(int j=0;j<col_count;j++){int u=rows[i],v=cols[j];long d=ctx.ddg[child][u][v];b.weights[i][j]=d==INF?INF:d+potential[u]-potential[v];}
}
fn void build_blocks_rec(Context* ctx,int child,int lo,int hi,long* potential,Block* blocks,int* count) {
    if(hi-lo<=1)return; Piece p=ctx.pieces[child];int middle=(lo+hi)/2;
    add_block(ctx,child,&p.boundary[lo],middle-lo,&p.boundary[middle],hi-middle,potential,blocks,count);
    add_block(ctx,child,&p.boundary[middle],hi-middle,&p.boundary[lo],middle-lo,potential,blocks,count);
    build_blocks_rec(ctx,child,lo,middle,potential,blocks,count);build_blocks_rec(ctx,child,middle,hi,potential,blocks,count);
}
fn void activate(int vertex,long value,Block* blocks,int count,bool* settled){
    for(int bi=0;bi<count;bi++){Block* b=&blocks[bi];for(int i=0;i<b.row_count;i++)if(b.rows[i]==vertex)for(int j=0;j<b.column_count;j++){
        int target=b.columns[j];long weight=b.weights[i][j];if(settled[target]||weight==INF)continue;long candidate=value+weight;
        if(candidate<b.best_value[j]||(candidate==b.best_value[j]&&vertex<b.best_row[j])){b.best_value[j]=candidate;b.best_row[j]=vertex;}
    }}
}
fn void settle(int vertex,bool* settled,Block* blocks,int count){settled[vertex]=true;for(int bi=0;bi<count;bi++)for(int j=0;j<blocks[bi].column_count;j++)if(blocks[bi].columns[j]==vertex){blocks[bi].best_value[j]=INF;blocks[bi].best_row[j]=MAX_N;}}
fn void dijkstra(Context* ctx,int* nodes,int node_count,Block* blocks,int count,long* seeds,long* labels){
    bool[MAX_N] settled={};for(int v=0;v<ctx.n;v++)labels[v]=INF;
    for(int bi=0;bi<count;bi++)for(int j=0;j<blocks[bi].column_count;j++){blocks[bi].best_value[j]=INF;blocks[bi].best_row[j]=MAX_N;}
    for(int i=0;i<node_count;i++)if(seeds[nodes[i]]<labels[nodes[i]])labels[nodes[i]]=seeds[nodes[i]];
    for(int i=0;i<node_count;i++){int v=nodes[i];if(labels[v]!=INF)activate(v,labels[v],blocks,count,&settled);}
    while(true){int best=-1,best_row=MAX_N;long best_value=INF;
        for(int i=0;i<node_count;i++){int v=nodes[i];long d=labels[v];if(!settled[v]&&d!=INF&&(d<best_value||(d==best_value&&v<best))){best=v;best_value=d;best_row=-1;}}
        for(int bi=0;bi<count;bi++)for(int j=0;j<blocks[bi].column_count;j++){Block* b=&blocks[bi];int v=b->columns[j],row=b->best_row[j];long d=b->best_value[j];if(settled[v]||d==INF)continue;
            if(d<best_value||(d==best_value&&(best<0||v<best))||(d==best_value&&v==best&&row<best_row)){best=v;best_value=d;best_row=row;}}
        if(best<0)break;if(best_value<labels[best])labels[best]=best_value;settle(best,&settled,blocks,count);activate(best,labels[best],blocks,count,&settled);
    }
}

fn bool build_piece(Context* ctx,int index,Block* blocks){
    Piece piece=ctx.pieces[index];for(int u=0;u<ctx.n;u++)for(int v=0;v<ctx.n;v++)ctx.ddg[index][u][v]=INF;
    if(piece.left==-1){Arc[MAX_BASE_ARCS] arcs={};int arc_count=0;int[MAX_N] nodes={};int node_count=0;
        for(int e=0;e<ctx.m;e++)if((piece.arc_mask&(1UL<<e))!=0)arcs[arc_count++]=ctx.arcs[e];
        for(int v=0;v<ctx.n;v++)if((piece.vertex_mask&(1U<<v))!=0)nodes[node_count++]=v;
        long[MAX_N] potential={};if(!bellman(ctx,&nodes[0],node_count,&arcs[0],arc_count,&potential[0]))return false;
        for(int i=0;i<piece.boundary_count;i++){long[MAX_N] seeds={};long[MAX_N] labels={};for(int v=0;v<ctx.n;v++)seeds[v]=INF;seeds[piece.boundary[i]]=0;
            if(!seeded(ctx,&arcs[0],arc_count,&seeds[0],&labels[0]))return false;for(int j=0;j<piece.boundary_count;j++)ctx.ddg[index][piece.boundary[i]][piece.boundary[j]]=labels[piece.boundary[j]];}
        return true;
    }
    int left=piece.left,right=piece.right;bool[MAX_N] present={};Piece lp=ctx.pieces[left],rp=ctx.pieces[right];
    for(int i=0;i<lp.boundary_count;i++)present[lp.boundary[i]]=true;for(int i=0;i<rp.boundary_count;i++)present[rp.boundary[i]]=true;
    int[MAX_N] nodes={};int node_count=0;for(int v=0;v<ctx.n;v++)if(present[v])nodes[node_count++]=v;
    Arc[2*MAX_B*MAX_B] union_arcs={};int union_count=0;
    for(int side=0;side<2;side++){int child=side==0?left:right;Piece cp=ctx.pieces[child];for(int i=0;i<cp.boundary_count;i++)for(int j=0;j<cp.boundary_count;j++){
        int u=cp.boundary[i],v=cp.boundary[j];long d=ctx.ddg[child][u][v];if(u!=v&&d!=INF)union_arcs[union_count++]=(Arc){u,v,d};}}
    long* potential=&ctx.potential[index][0];for(int v=0;v<ctx.n;v++)potential[v]=0;
    if(!bellman(ctx,&nodes[0],node_count,&union_arcs[0],union_count,potential))return false;
    for(int e=0;e<union_count;e++){Arc a=union_arcs[e];if(a.weight+potential[a.tail]-potential[a.head]<0)return false;}
    int count=0;for(int side=0;side<2;side++){int child=side==0?left:right;if(!check_monge(ctx,child,0,ctx.pieces[child].boundary_count))return false;build_blocks_rec(ctx,child,0,ctx.pieces[child].boundary_count,potential,blocks,&count);}
    if(count>MAX_BLOCKS)return false;
    for(int i=0;i<piece.boundary_count;i++){long[MAX_N] seeds={};long[MAX_N] labels={};for(int v=0;v<ctx.n;v++)seeds[v]=INF;seeds[piece.boundary[i]]=0;dijkstra(ctx,&nodes[0],node_count,blocks,count,&seeds[0],&labels[0]);
        for(int j=0;j<piece.boundary_count;j++){int s=piece.boundary[i],t=piece.boundary[j];long d=labels[t];ctx.ddg[index][s][t]=d==INF?INF:d-potential[s]+potential[t];}}
    return true;
}

fn void expand(Context* ctx,int index,long* known,long* result,Block* blocks){
    Piece piece=ctx.pieces[index];if(piece.left==-1){Arc[MAX_BASE_ARCS] arcs={};int count=0;for(int e=0;e<ctx.m;e++)if((piece.arc_mask&(1UL<<e))!=0)arcs[count++]=ctx.arcs[e];long[MAX_N] labels={};if(!seeded(ctx,&arcs[0],count,known,&labels[0]))return;
        for(int v=0;v<ctx.n;v++)if((piece.vertex_mask&(1U<<v))!=0&&labels[v]<result[v])result[v]=labels[v];return;}
    int left=piece.left,right=piece.right;bool[MAX_N] present={};Piece lp=ctx.pieces[left],rp=ctx.pieces[right];for(int i=0;i<lp.boundary_count;i++)present[lp.boundary[i]]=true;for(int i=0;i<rp.boundary_count;i++)present[rp.boundary[i]]=true;
    int[MAX_N] nodes={};int node_count=0;for(int v=0;v<ctx.n;v++)if(present[v])nodes[node_count++]=v;long* potential=&ctx.potential[index][0];int count=0;
    build_blocks_rec(ctx,left,0,lp.boundary_count,potential,blocks,&count);build_blocks_rec(ctx,right,0,rp.boundary_count,potential,blocks,&count);
    long[MAX_N] seeds={};for(int v=0;v<ctx.n;v++)seeds[v]=INF;for(int i=0;i<piece.boundary_count;i++){int v=piece.boundary[i];if(known[v]!=INF)seeds[v]=known[v]-potential[v];}
    long[MAX_N] reduced={};dijkstra(ctx,&nodes[0],node_count,blocks,count,&seeds[0],&reduced[0]);long[MAX_N] raw={};for(int v=0;v<ctx.n;v++)if(reduced[v]!=INF)raw[v]=reduced[v]+potential[v];
    for(int side=0;side<2;side++){int child=side==0?left:right;long[MAX_N] child_known={};for(int v=0;v<ctx.n;v++)child_known[v]=INF;Piece cp=ctx.pieces[child];for(int i=0;i<cp.boundary_count;i++)child_known[cp.boundary[i]]=raw[cp.boundary[i]];expand(ctx,child,&child_known[0],result,blocks);}
}

fn void put_i64(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b));}

fn long fakcharoenphol_rao_planar_sssp(long* input, usz length, char* output, usz capacity) @export("fakcharoenphol_rao_planar_sssp") {
    Context ctx={};if(!parse(&ctx,input,length))return -1;
    int[MAX_N] all_nodes={};for(int v=0;v<ctx.n;v++)all_nodes[v]=v;long[MAX_N] global_potential={};
    if(!bellman(&ctx,&all_nodes[0],ctx.n,&ctx.arcs[0],ctx.m,&global_potential[0]))return -1;
    Block[MAX_BLOCKS] blocks={};for(int p=0;p<ctx.piece_count;p++)if(!build_piece(&ctx,p,&blocks[0]))return -1;
    long[MAX_N] result={},known={};for(int v=0;v<ctx.n;v++){result[v]=INF;known[v]=INF;}known[ctx.source]=0;
    expand(&ctx,ctx.piece_count-1,&known[0],&result[0],&blocks[0]);usz required=(usz)(ctx.n*8);
    if(output==null||capacity<required)return -2;
    for(int v=0;v<ctx.n;v++)put_i64(output,(usz)(v*8),result[v]==INF?9223372036854775807L:result[v]);
    return (long)required;
}
