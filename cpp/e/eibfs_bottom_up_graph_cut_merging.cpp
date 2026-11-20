/* Clean-room bounded Excesses IBFS maximum flow. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int NMAX = 8, MMAX = 24, INPUT_MAX = 77, EVENT_MAX = 100000;
constexpr int FREE_TREE = 0, S_TREE = 1, T_TREE = 2;
struct State {
    int n, source, sink;
    bool forward = true;
    int kind[NMAX]{}, parent[NMAX];
    std::int64_t original[NMAX][NMAX]{}, residual[NMAX][NMAX]{};
    std::int64_t balance[NMAX]{}, ds[NMAX]{}, dt[NMAX]{}, Ds = 0, Dt = 0;
    bool orphaned[NMAX]{};
    int events = 0;
};
int root(State& s, int v) {
    for (int i = 0; i < s.n; ++i) { if (s.parent[v] < 0) return v; v = s.parent[v]; }
    return -1;
}
std::int64_t bottleneck(State& s, int v, int kind) {
    std::int64_t answer = 2401;
    for (int i = 0; i < s.n; ++i) {
        int p = s.parent[v]; if (p < 0) return answer;
        answer = answer < (kind == S_TREE ? s.residual[p][v] : s.residual[v][p])
            ? answer : (kind == S_TREE ? s.residual[p][v] : s.residual[v][p]);
        v = p;
    }
    return 0;
}
void push(State& s, int u, int v, std::int64_t d) {
    s.residual[u][v] -= d; s.residual[v][u] += d;
    if (u != s.source && u != s.sink) s.balance[u] -= d;
    if (v != s.source && v != s.sink) s.balance[v] += d;
}
void mark(State& s, int v, int q[512], int& tail) { if (!s.orphaned[v]) { s.orphaned[v] = true; q[tail++] = v; } }
void detach(State& s, int v, int kind, int q[512], int& tail) {
    for (int c = 0; c < s.n; ++c) if (s.kind[c] == kind && s.parent[c] == v) { s.parent[c] = -1; mark(s, c, q, tail); }
}
void adopt(State& s, int v, int kind, int q[512], int& tail) {
    const bool sink_side = kind == T_TREE;
    s.orphaned[v] = false;
    std::int64_t* labels = sink_side ? s.dt : s.ds;
    const std::int64_t old = labels[v];
    auto cap = [&](int u) { return sink_side ? s.residual[v][u] : s.residual[u][v]; };
    for (int u = 0; u < s.n; ++u)
        if (u != v && s.kind[u] == kind && cap(u) > 0 && labels[v] == labels[u] + 1) { s.parent[v] = u; return; }
    const std::int64_t frontier = sink_side ? s.Dt : s.Ds;
    const std::int64_t limit = frontier - ((sink_side ? s.forward : !s.forward) ? 1 : 0);
    std::int64_t best = 4 * s.n;
    for (int u = 0; u < s.n; ++u)
        if (u != v && s.kind[u] == kind && cap(u) > 0 && labels[u] <= limit && labels[u] < best) best = labels[u];
    int p = -1;
    for (int u = 0; u < s.n; ++u) if (u != v && s.kind[u] == kind && cap(u) > 0 && labels[u] == best) { p = u; break; }
    if (p >= 0 && best + 1 > old) {
        detach(s, v, kind, q, tail); s.parent[v] = p; labels[v] = best + 1; return;
    }
    detach(s, v, kind, q, tail); s.parent[v] = -1; s.kind[v] = FREE_TREE;
    if (sink_side && s.balance[v] > 0) { s.kind[v] = S_TREE; s.ds[v] = s.Ds + (s.forward ? 1 : 0); }
    if (!sink_side && s.balance[v] < 0) { s.kind[v] = T_TREE; s.dt[v] = s.Dt + (s.forward ? 0 : 1); }
}
void repair_orphans(State& s, int kind, int q[512], int head, int tail) {
    while (head < tail) { int v = q[head++]; s.orphaned[v] = false; if (s.kind[v] == kind) adopt(s, v, kind, q, tail); }
}
void drain(State& s, int v, int kind) {
    const int root_v = root(s, v); if (root_v < 0) return;
    int q[512], head = 0, tail = 0, x = v;
    while ((kind == T_TREE ? s.balance[x] > 0 : s.balance[x] < 0) && s.parent[x] >= 0) {
        const int p = s.parent[x];
        const std::int64_t capacity = kind == T_TREE ? s.residual[x][p] : s.residual[p][x];
        const std::int64_t need = kind == T_TREE ? s.balance[x] : -s.balance[x];
        const std::int64_t d = need < capacity ? need : capacity;
        if (d > 0) { if (kind == T_TREE) push(s, x, p, d); else push(s, p, x, d); }
        const std::int64_t after = kind == T_TREE ? s.balance[x] : -s.balance[x];
        const std::int64_t rest = kind == T_TREE ? s.residual[x][p] : s.residual[p][x];
        if (rest == 0 && after >= 0) { s.parent[x] = -1; mark(s, x, q, tail); break; }
        if (after == 0) break;
        x = p;
    }
    if (kind == T_TREE && root_v != s.sink && s.kind[root_v] == kind && s.balance[root_v] >= 0) { s.parent[root_v] = -1; mark(s, root_v, q, tail); }
    if (kind == S_TREE && root_v != s.source && s.kind[root_v] == kind && s.balance[root_v] <= 0) { s.parent[root_v] = -1; mark(s, root_v, q, tail); }
    repair_orphans(s, kind, q, head, tail);
}
void repair(State& s) {
    for (;;) {
        bool done = false;
        for (int v = 0; v < s.n; ++v) if (s.kind[v] == T_TREE && s.balance[v] > 0) { drain(s, v, T_TREE); done = true; break; }
        if (done) continue;
        for (int v = 0; v < s.n; ++v) if (s.kind[v] == S_TREE && s.balance[v] < 0) { drain(s, v, S_TREE); done = true; break; }
        if (!done) return;
    }
}
bool augment(State& s, int v, int w) {
    const int rs = root(s, v), rt = root(s, w); if (rs < 0 || rt < 0 || s.residual[v][w] <= 0) return false;
    const std::int64_t c = s.residual[v][w], bs = bottleneck(s, v, S_TREE), bt = bottleneck(s, w, T_TREE);
    std::int64_t d;
    if (rs == s.source && rt == s.sink) d = c;
    else if (rs == s.source) d = bs < c ? bs : c;
    else if (rt == s.sink) d = c < bt ? c : bt;
    else { d = s.balance[rs]; if (bs < d) d = bs; if (c < d) d = c; if (bt < d) d = bt; if (-s.balance[rt] < d) d = -s.balance[rt]; }
    if (d <= 0) return false;
    push(s, v, w, d); repair(s); return true;
}
std::int64_t solve(State& s) {
    for (int phase = 0; phase < 4 * s.n + 4; ++phase) {
        bool finished = false;
        for (;;) {
            bool restart = false;
            if (s.forward) {
                for (int v = 0; v < s.n && !restart; ++v) if (s.kind[v] == S_TREE && s.ds[v] == s.Ds)
                    for (int w = 0; w < s.n; ++w) if (s.residual[v][w] > 0 && s.kind[w] != S_TREE) {
                        if (s.kind[w] == FREE_TREE) { s.kind[w] = S_TREE; s.parent[w] = v; s.ds[w] = s.Ds + 1; }
                        else if (s.kind[w] == T_TREE && augment(s, v, w)) { if (++s.events > EVENT_MAX) return -1; restart = true; break; }
                    }
                bool next = false; for (int v = 0; v < s.n; ++v) if (s.kind[v] == S_TREE && s.ds[v] == s.Ds + 1) next = true;
                if (!restart) { if (!next) finished = true; else ++s.Ds; break; }
            } else {
                for (int w = 0; w < s.n && !restart; ++w) if (s.kind[w] == T_TREE && s.dt[w] == s.Dt)
                    for (int v = 0; v < s.n; ++v) if (s.residual[v][w] > 0 && s.kind[v] != T_TREE) {
                        if (s.kind[v] == FREE_TREE) { s.kind[v] = T_TREE; s.parent[v] = w; s.dt[v] = s.Dt + 1; }
                        else if (s.kind[v] == S_TREE && augment(s, v, w)) { if (++s.events > EVENT_MAX) return -1; restart = true; break; }
                    }
                bool next = false; for (int v = 0; v < s.n; ++v) if (s.kind[v] == T_TREE && s.dt[v] == s.Dt + 1) next = true;
                if (!restart) { if (!next) finished = true; else ++s.Dt; break; }
            }
        }
        if (finished) break;
        s.forward = !s.forward;
    }
    bool reachable[NMAX]{}; int queue[NMAX]{}, head = 0, tail = 0;
    for (int v = 0; v < s.n; ++v) if (s.kind[v] == S_TREE) { reachable[v] = true; queue[tail++] = v; }
    while (head < tail) { const int u = queue[head++]; for (int v = 0; v < s.n; ++v)
        if (s.residual[u][v] > 0 && !reachable[v]) { reachable[v] = true; queue[tail++] = v; } }
    std::int64_t cut = 0;
    for (int u = 0; u < s.n; ++u) if (reachable[u]) for (int v = 0; v < s.n; ++v) if (!reachable[v]) cut += s.original[u][v];
    return cut;
}
}

extern "C" std::int64_t eibfs_maxflow(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 4 || length > INPUT_MAX) return -1;
    const auto nv = input[0], mv = input[1], sv = input[2], tv = input[3];
    if (nv < 2 || nv > NMAX || mv < 0 || mv > MMAX || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv || length != 4 + 3 * static_cast<std::size_t>(mv)) return -1;
    State s{}; s.n = static_cast<int>(nv); s.source = static_cast<int>(sv); s.sink = static_cast<int>(tv);
    for (int v = 0; v < s.n; ++v) s.parent[v] = -1;
    for (int e = 0; e < mv; ++e) {
        const auto u = input[4 + 3 * e], v = input[5 + 3 * e], c = input[6 + 3 * e];
        if (u < 0 || u >= nv || v < 0 || v >= nv || u == v || c < 0 || c > 100) return -1;
        s.original[u][v] += c; s.residual[u][v] += c;
    }
    s.kind[s.source] = S_TREE; s.kind[s.sink] = T_TREE;
    return solve(s);
}

namespace {
constexpr int MERGE_NMAX = 6, MERGE_MMAX = 6, MERGE_INPUT_MAX = 46;
struct MergeEdge { int u, v; std::int64_t uv, vu; };
int merge_find(int parent[4], int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
std::int64_t merge_component_flow(int n, const int active[MERGE_NMAX],
                                  const std::int64_t source_caps[MERGE_NMAX],
                                  const std::int64_t sink_caps[MERGE_NMAX],
                                  const MergeEdge edges[MERGE_MMAX], int m) {
    int local[MERGE_NMAX]; for (int i = 0; i < MERGE_NMAX; ++i) local[i] = -1;
    int k = 0; for (int v = 0; v < n; ++v) if (active[v]) local[v] = k++;
    std::int64_t frame[4 + 3 * (2 * MERGE_NMAX + 2 * MERGE_MMAX)]{};
    const int source = k, sink = k + 1;
    frame[0] = k + 2; frame[2] = source; frame[3] = sink;
    std::size_t at = 4; int arc_count = 0;
    for (int v = 0; v < n; ++v) if (active[v]) {
        frame[at++] = source; frame[at++] = local[v]; frame[at++] = source_caps[v]; ++arc_count;
        frame[at++] = local[v]; frame[at++] = sink; frame[at++] = sink_caps[v]; ++arc_count;
    }
    for (int e = 0; e < m; ++e) if (local[edges[e].u] >= 0 && local[edges[e].v] >= 0) {
        frame[at++] = local[edges[e].u]; frame[at++] = local[edges[e].v]; frame[at++] = edges[e].uv; ++arc_count;
        frame[at++] = local[edges[e].v]; frame[at++] = local[edges[e].u]; frame[at++] = edges[e].vu; ++arc_count;
    }
    frame[1] = arc_count;
    return eibfs_maxflow(frame, at);
}
}

extern "C" std::int64_t eibfs_bottom_up_graph_cut_merging(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 3 || length > MERGE_INPUT_MAX) return -1;
    const auto nv = input[0], mv = input[1], bv = input[2];
    if (nv < 2 || nv > MERGE_NMAX || mv < 0 || mv > MERGE_MMAX || bv < 1 || bv > 4 || bv > nv || length != 3 + 3 * nv + 4 * mv) return -1;
    const int n = static_cast<int>(nv), m = static_cast<int>(mv), blocks = static_cast<int>(bv);
    int block[MERGE_NMAX], seen[4]{};
    std::int64_t source_caps[MERGE_NMAX]{}, sink_caps[MERGE_NMAX]{};
    for (int v = 0; v < n; ++v) { const auto id = input[3 + v]; if (id < 0 || id >= blocks) return -1; block[v] = static_cast<int>(id); seen[block[v]] = 1; }
    for (int b = 0; b < blocks; ++b) if (!seen[b]) return -1;
    for (int v = 0; v < n; ++v) { source_caps[v] = input[3 + n + v]; sink_caps[v] = input[3 + 2 * n + v]; if (source_caps[v] < 0 || source_caps[v] > 7 || sink_caps[v] < 0 || sink_caps[v] > 7) return -1; }
    MergeEdge edges[MERGE_MMAX]{};
    for (int e = 0; e < m; ++e) { const std::size_t p = 3 + 3 * n + 4 * e; const auto u=input[p],v=input[p+1],uv=input[p+2],vu=input[p+3]; if (u<0||u>=n||v<0||v>=n||u==v||uv<0||uv>7||vu<0||vu>7) return -1; edges[e]={static_cast<int>(u),static_cast<int>(v),uv,vu}; }
    int tags[MERGE_NMAX]{}; std::int64_t flow[4]{};
    for (int b = 0; b < blocks; ++b) {
        int vertices[MERGE_NMAX], k=0, active[MERGE_NMAX]{};
        for(int v=0;v<n;++v)if(block[v]==b){vertices[k++]=v;active[v]=1;}
        std::int64_t best_cost = (std::int64_t(1) << 60); unsigned best_mask=0;
        for(unsigned mask=0;mask<(1u<<k);++mask){std::int64_t cost=0;
            for(int i=0;i<k;++i){int v=vertices[i];cost+=(mask&(1u<<i))?sink_caps[v]:source_caps[v];}
            for(int e=0;e<m;++e)if(block[edges[e].u]==b&&block[edges[e].v]==b){int iu=0,iv=0;while(vertices[iu]!=edges[e].u)++iu;while(vertices[iv]!=edges[e].v)++iv;bool us=(mask&(1u<<iu))!=0,vs=(mask&(1u<<iv))!=0;if(us&&!vs)cost+=edges[e].uv;else if(vs&&!us)cost+=edges[e].vu;}
            if(cost<best_cost||(cost==best_cost&&mask<best_mask)){best_cost=cost;best_mask=mask;}}
        for(int i=0;i<k;++i)tags[vertices[i]]=(best_mask&(1u<<i))?1:2;
        flow[b]=merge_component_flow(n,active,source_caps,sink_caps,edges,m);if(flow[b]<0)return -1;
    }
    int score[4][4]{},has[4][4]{};
    for(int e=0;e<m;++e)if(block[edges[e].u]!=block[edges[e].v]&&(edges[e].uv||edges[e].vu)){int a=block[edges[e].u],b=block[edges[e].v];if(a>b){int t=a;a=b;b=t;}has[a][b]=1;if(tags[edges[e].u]!=tags[edges[e].v])score[a][b]+=(edges[e].uv>0)+(edges[e].vu>0);}
    int pair_a[6],pair_b[6],pair_score[6],pair_count=0;
    for(int a=0;a<blocks;++a)for(int b=a+1;b<blocks;++b)if(has[a][b]){int pos=pair_count++;while(pos>0&&(pair_score[pos-1]<score[a][b]||(pair_score[pos-1]==score[a][b]&&(pair_a[pos-1]>a||(pair_a[pos-1]==a&&pair_b[pos-1]>b))))){pair_a[pos]=pair_a[pos-1];pair_b[pos]=pair_b[pos-1];pair_score[pos]=pair_score[pos-1];--pos;}pair_a[pos]=a;pair_b[pos]=b;pair_score[pos]=score[a][b];}
    int parent[4]={0,1,2,3};
    for(int i=0;i<pair_count;++i){int a=merge_find(parent,pair_a[i]),b=merge_find(parent,pair_b[i]);if(a==b)continue;int root=a<b?a:b,other=a<b?b:a;parent[other]=root;int active[MERGE_NMAX]{};for(int v=0;v<n;++v)active[v]=merge_find(parent,block[v])==root;flow[root]=merge_component_flow(n,active,source_caps,sink_caps,edges,m);if(flow[root]<0)return -1;flow[other]=0;}
    std::int64_t answer=0;for(int b=0;b<blocks;++b)if(merge_find(parent,b)==b)answer+=flow[b];return answer;
}
