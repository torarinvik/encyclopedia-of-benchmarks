/* Clean-room bounded Excesses IBFS maximum flow. */
#include <stddef.h>
#include <stdint.h>

#define NMAX 8
#define MMAX 24
#define INPUT_MAX (4 + 3 * MMAX + 1)
#define FLOW_MAX INT64_C(2400)
#define EVENT_MAX 100000

enum { FREE_TREE = 0, S_TREE = 1, T_TREE = 2 };
typedef struct {
    int n, source, sink, forward;
    int kind[NMAX], parent[NMAX];
    int64_t original[NMAX * NMAX], residual[NMAX * NMAX];
    int64_t balance[NMAX], ds[NMAX], dt[NMAX], Ds, Dt;
    int orphaned[NMAX];
    int steps;
} Eibfs;

static void mark_orphan(Eibfs *s, int v, int *queue, int *tail) {
    if (!s->orphaned[v]) { s->orphaned[v] = 1; queue[(*tail)++] = v; }
}

static int root_of(const Eibfs *s, int v) {
    for (int k = 0; k < s->n; ++k) {
        if (s->parent[v] < 0) return v;
        v = s->parent[v];
    }
    return -1;
}

static int64_t min64(int64_t a, int64_t b) { return a < b ? a : b; }

static int64_t bottleneck(const Eibfs *s, int v, int kind) {
    int64_t answer = FLOW_MAX + 1;
    for (int k = 0; k < s->n; ++k) {
        const int p = s->parent[v];
        if (p < 0) return answer;
        const int64_t cap = kind == S_TREE ? s->residual[p * NMAX + v]
                                           : s->residual[v * NMAX + p];
        answer = min64(answer, cap);
        v = p;
    }
    return 0;
}

static void push(Eibfs *s, int u, int v, int64_t amount) {
    s->residual[u * NMAX + v] -= amount;
    s->residual[v * NMAX + u] += amount;
    if (u != s->source && u != s->sink) s->balance[u] -= amount;
    if (v != s->source && v != s->sink) s->balance[v] += amount;
}

static void detach_children(Eibfs *s, int v, int kind, int *queue, int *tail) {
    for (int child = 0; child < s->n; ++child) {
        if (s->kind[child] == kind && s->parent[child] == v) {
            s->parent[child] = -1;
            mark_orphan(s, child, queue, tail);
        }
    }
}

static void adopt_t(Eibfs *s, int v, int *queue, int *tail) {
    s->orphaned[v] = 0;
    const int old = (int)s->dt[v];
    int exact = -1;
    for (int u = 0; u < s->n; ++u)
        if (u != v && s->kind[u] == T_TREE && s->residual[v * NMAX + u] > 0 &&
            s->dt[v] == s->dt[u] + 1) { exact = u; break; }
    if (exact >= 0) { s->parent[v] = exact; return; }
    const int limit = (int)s->Dt - (s->forward ? 1 : 0);
    int best = 4 * s->n;
    for (int u = 0; u < s->n; ++u)
        if (u != v && s->kind[u] == T_TREE && s->residual[v * NMAX + u] > 0 &&
            s->dt[u] <= limit && s->dt[u] < best) best = (int)s->dt[u];
    int parent = -1;
    if (best < 4 * s->n)
        for (int u = 0; u < s->n; ++u)
            if (u != v && s->kind[u] == T_TREE && s->residual[v * NMAX + u] > 0 &&
                s->dt[u] == best) { parent = u; break; }
    if (parent >= 0 && best + 1 > old) {
        detach_children(s, v, T_TREE, queue, tail);
        s->parent[v] = parent; s->dt[v] = best + 1; return;
    }
    detach_children(s, v, T_TREE, queue, tail);
    s->parent[v] = -1; s->kind[v] = FREE_TREE;
    if (s->balance[v] > 0) {
        s->kind[v] = S_TREE;
        s->ds[v] = s->Ds + (s->forward ? 1 : 0);
    }
}

static void adopt_s(Eibfs *s, int v, int *queue, int *tail) {
    s->orphaned[v] = 0;
    const int old = (int)s->ds[v];
    int exact = -1;
    for (int u = 0; u < s->n; ++u)
        if (u != v && s->kind[u] == S_TREE && s->residual[u * NMAX + v] > 0 &&
            s->ds[v] == s->ds[u] + 1) { exact = u; break; }
    if (exact >= 0) { s->parent[v] = exact; return; }
    const int limit = (int)s->Ds - (s->forward ? 0 : 1);
    int best = 4 * s->n;
    for (int u = 0; u < s->n; ++u)
        if (u != v && s->kind[u] == S_TREE && s->residual[u * NMAX + v] > 0 &&
            s->ds[u] <= limit && s->ds[u] < best) best = (int)s->ds[u];
    int parent = -1;
    if (best < 4 * s->n)
        for (int u = 0; u < s->n; ++u)
            if (u != v && s->kind[u] == S_TREE && s->residual[u * NMAX + v] > 0 &&
                s->ds[u] == best) { parent = u; break; }
    if (parent >= 0 && best + 1 > old) {
        detach_children(s, v, S_TREE, queue, tail);
        s->parent[v] = parent; s->ds[v] = best + 1; return;
    }
    detach_children(s, v, S_TREE, queue, tail);
    s->parent[v] = -1; s->kind[v] = FREE_TREE;
    if (s->balance[v] < 0) {
        s->kind[v] = T_TREE;
        s->dt[v] = s->Dt + (s->forward ? 0 : 1);
    }
}

static void repair_orphans(Eibfs *s, int kind, int *queue, int head, int tail) {
    while (head < tail) {
        const int v = queue[head++];
        s->orphaned[v] = 0;
        if (s->kind[v] == kind) {
            if (kind == T_TREE) adopt_t(s, v, queue, &tail);
            else adopt_s(s, v, queue, &tail);
        }
    }
}

static void drain_t(Eibfs *s, int v) {
    int root = root_of(s, v), queue[512], head = 0, tail = 0;
    if (root < 0) return;
    int x = v;
    while (s->balance[x] > 0 && s->parent[x] >= 0) {
        const int p = s->parent[x];
        const int64_t amount = min64(s->balance[x], s->residual[x * NMAX + p]);
        if (amount > 0) push(s, x, p, amount);
        if (s->residual[x * NMAX + p] == 0 && s->balance[x] >= 0) {
            s->parent[x] = -1; mark_orphan(s, x, queue, &tail); break;
        }
        if (s->balance[x] == 0) break;
        x = p;
    }
    if (root != s->sink && s->kind[root] == T_TREE && s->balance[root] >= 0) {
        s->parent[root] = -1; mark_orphan(s, root, queue, &tail);
    }
    repair_orphans(s, T_TREE, queue, head, tail);
}

static void drain_s(Eibfs *s, int v) {
    int root = root_of(s, v), queue[512], head = 0, tail = 0;
    if (root < 0) return;
    int x = v;
    while (s->balance[x] < 0 && s->parent[x] >= 0) {
        const int p = s->parent[x];
        const int64_t amount = min64(-s->balance[x], s->residual[p * NMAX + x]);
        if (amount > 0) push(s, p, x, amount);
        if (s->residual[p * NMAX + x] == 0 && s->balance[x] <= 0) {
            s->parent[x] = -1; mark_orphan(s, x, queue, &tail); break;
        }
        if (s->balance[x] == 0) break;
        x = p;
    }
    if (root != s->source && s->kind[root] == S_TREE && s->balance[root] <= 0) {
        s->parent[root] = -1; mark_orphan(s, root, queue, &tail);
    }
    repair_orphans(s, S_TREE, queue, head, tail);
}

static void repair(Eibfs *s) {
    for (;;) {
        int found = 0;
        for (int v = 0; v < s->n; ++v)
            if (s->kind[v] == T_TREE && s->balance[v] > 0) { drain_t(s, v); found = 1; break; }
        if (found) continue;
        for (int v = 0; v < s->n; ++v)
            if (s->kind[v] == S_TREE && s->balance[v] < 0) { drain_s(s, v); found = 1; break; }
        if (!found) return;
    }
}

static int augment(Eibfs *s, int v, int w) {
    const int rs = root_of(s, v), rt = root_of(s, w);
    if (rs < 0 || rt < 0 || s->residual[v * NMAX + w] <= 0) return 0;
    const int64_t connector = s->residual[v * NMAX + w];
    const int64_t bs = bottleneck(s, v, S_TREE), bt = bottleneck(s, w, T_TREE);
    int64_t amount;
    if (rs == s->source && rt == s->sink) amount = connector;
    else if (rs == s->source) amount = min64(bs, connector);
    else if (rt == s->sink) amount = min64(connector, bt);
    else amount = min64(min64(min64(min64(s->balance[rs], bs), connector), bt), -s->balance[rt]);
    if (amount <= 0) return 0;
    push(s, v, w, amount); repair(s); return 1;
}

int64_t eibfs_maxflow(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > INPUT_MAX) return -1;
    const int64_t nv = input[0], mv = input[1], sv = input[2], tv = input[3];
    if (nv < 2 || nv > NMAX || mv < 0 || mv > MMAX || sv < 0 || sv >= nv ||
        tv < 0 || tv >= nv || sv == tv || length != (size_t)(4 + 3 * mv)) return -1;
    Eibfs s = {0}; s.n = (int)nv; s.source = (int)sv; s.sink = (int)tv; s.forward = 1;
    for (int v = 0; v < s.n; ++v) s.parent[v] = -1;
    for (int e = 0; e < (int)mv; ++e) {
        const int64_t u = input[4 + 3 * e], v = input[5 + 3 * e], c = input[6 + 3 * e];
        if (u < 0 || u >= nv || v < 0 || v >= nv || u == v || c < 0 || c > 100) return -1;
        s.original[(size_t)u * NMAX + (size_t)v] += c;
        s.residual[(size_t)u * NMAX + (size_t)v] += c;
    }
    s.kind[s.source] = S_TREE; s.kind[s.sink] = T_TREE;
    for (int phase = 0; phase < 4 * s.n + 4; ++phase) {
        int restart, finished = 0;
        do {
            restart = 0;
            if (s.forward) {
                for (int v = 0; v < s.n && !restart; ++v) {
                    if (s.kind[v] != S_TREE || s.ds[v] != s.Ds) continue;
                    for (int w = 0; w < s.n; ++w) {
                        if (s.residual[v * NMAX + w] <= 0 || s.kind[w] == S_TREE) continue;
                        if (s.kind[w] == FREE_TREE) {
                            s.kind[w] = S_TREE; s.parent[w] = v; s.ds[w] = s.Ds + 1;
                        } else if (s.kind[w] == T_TREE && augment(&s, v, w)) {
                            if (++s.steps > EVENT_MAX) return -1;
                            restart = 1; break;
                        }
                    }
                }
                if (!restart) {
                    int next = 0;
                    for (int v = 0; v < s.n; ++v) if (s.kind[v] == S_TREE && s.ds[v] == s.Ds + 1) next = 1;
                    if (!next) { finished = 1; break; }
                    ++s.Ds;
                }
            } else {
                for (int w = 0; w < s.n && !restart; ++w) {
                    if (s.kind[w] != T_TREE || s.dt[w] != s.Dt) continue;
                    for (int v = 0; v < s.n; ++v) {
                        if (s.residual[v * NMAX + w] <= 0 || s.kind[v] == T_TREE) continue;
                        if (s.kind[v] == FREE_TREE) {
                            s.kind[v] = T_TREE; s.parent[v] = w; s.dt[v] = s.Dt + 1;
                        } else if (s.kind[v] == S_TREE && augment(&s, v, w)) {
                            if (++s.steps > EVENT_MAX) return -1;
                            restart = 1; break;
                        }
                    }
                }
                if (!restart) {
                    int next = 0;
                    for (int v = 0; v < s.n; ++v) if (s.kind[v] == T_TREE && s.dt[v] == s.Dt + 1) next = 1;
                    if (!next) { finished = 1; break; }
                    ++s.Dt;
                }
            }
        } while (restart);
        if (finished) break;
        s.forward = !s.forward;
    }
    int reachable[NMAX] = {0}, queue[NMAX], head = 0, tail = 0;
    for (int v = 0; v < s.n; ++v) if (s.kind[v] == S_TREE) {
        reachable[v] = 1; queue[tail++] = v;
    }
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < s.n; ++v) if (s.residual[u * NMAX + v] > 0 && !reachable[v]) {
            reachable[v] = 1; queue[tail++] = v;
        }
    }
    int64_t cut = 0;
    for (int u = 0; u < s.n; ++u) if (reachable[u])
        for (int v = 0; v < s.n; ++v) if (!reachable[v]) cut += s.original[u * NMAX + v];
    return cut;
}

#define MERGE_NMAX 6
#define MERGE_MMAX 6
#define MERGE_INPUT_MAX 46

typedef struct { int u, v; int64_t uv, vu; } MergeEdge;

static int merge_find(int parent[4], int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

static int64_t merge_component_flow(int n, const int active[MERGE_NMAX],
                                    const int64_t source_caps[MERGE_NMAX],
                                    const int64_t sink_caps[MERGE_NMAX],
                                    const MergeEdge edges[MERGE_MMAX], int m) {
    int local[MERGE_NMAX];
    for (int i = 0; i < MERGE_NMAX; ++i) local[i] = -1;
    int k = 0;
    for (int v = 0; v < n; ++v) if (active[v]) local[v] = k++;
    int64_t frame[4 + 3 * (2 * MERGE_NMAX + 2 * MERGE_MMAX)] = {0};
    const int source = k, sink = k + 1;
    frame[0] = k + 2; frame[2] = source; frame[3] = sink;
    size_t at = 4; int arc_count = 0;
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

int64_t eibfs_bottom_up_graph_cut_merging(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MERGE_INPUT_MAX) return -1;
    const int64_t nv = input[0], mv = input[1], bv = input[2];
    if (nv < 2 || nv > MERGE_NMAX || mv < 0 || mv > MERGE_MMAX || bv < 1 || bv > 4 || bv > nv ||
        length != (size_t)(3 + 3 * nv + 4 * mv)) return -1;
    const int n = (int)nv, m = (int)mv, blocks = (int)bv;
    int block[MERGE_NMAX], seen[4] = {0};
    int64_t source_caps[MERGE_NMAX], sink_caps[MERGE_NMAX];
    for (int v = 0; v < n; ++v) {
        const int64_t id = input[3 + v];
        if (id < 0 || id >= blocks) return -1;
        block[v] = (int)id; seen[block[v]] = 1;
    }
    for (int b = 0; b < blocks; ++b) if (!seen[b]) return -1;
    for (int v = 0; v < n; ++v) {
        source_caps[v] = input[3 + n + v]; sink_caps[v] = input[3 + 2 * n + v];
        if (source_caps[v] < 0 || source_caps[v] > 7 || sink_caps[v] < 0 || sink_caps[v] > 7) return -1;
    }
    MergeEdge edges[MERGE_MMAX] = {{0}};
    for (int e = 0; e < m; ++e) {
        const size_t p = (size_t)(3 + 3 * n + 4 * e);
        const int64_t u = input[p], v = input[p + 1], uv = input[p + 2], vu = input[p + 3];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || uv < 0 || uv > 7 || vu < 0 || vu > 7) return -1;
        edges[e] = (MergeEdge){(int)u, (int)v, uv, vu};
    }

    int tags[MERGE_NMAX] = {0};
    int64_t flow[4] = {0};
    for (int b = 0; b < blocks; ++b) {
        int vertices[MERGE_NMAX], k = 0, active[MERGE_NMAX] = {0};
        for (int v = 0; v < n; ++v) if (block[v] == b) { vertices[k++] = v; active[v] = 1; }
        int64_t best_cost = INT64_MAX; unsigned best_mask = 0;
        for (unsigned mask = 0; mask < (1u << k); ++mask) {
            int64_t cost = 0;
            for (int i = 0; i < k; ++i) {
                const int v = vertices[i]; cost += (mask & (1u << i)) ? sink_caps[v] : source_caps[v];
            }
            for (int e = 0; e < m; ++e) if (block[edges[e].u] == b && block[edges[e].v] == b) {
                int iu = 0, iv = 0; while (vertices[iu] != edges[e].u) ++iu; while (vertices[iv] != edges[e].v) ++iv;
                const int us = (mask & (1u << iu)) != 0, vs = (mask & (1u << iv)) != 0;
                if (us && !vs) cost += edges[e].uv; else if (vs && !us) cost += edges[e].vu;
            }
            if (cost < best_cost || (cost == best_cost && mask < best_mask)) { best_cost = cost; best_mask = mask; }
        }
        for (int i = 0; i < k; ++i) tags[vertices[i]] = (best_mask & (1u << i)) ? 1 : 2;
        flow[b] = merge_component_flow(n, active, source_caps, sink_caps, edges, m);
        if (flow[b] < 0) return -1;
    }

    int score[4][4] = {{0}}, has[4][4] = {{0}};
    for (int e = 0; e < m; ++e) if (block[edges[e].u] != block[edges[e].v] && (edges[e].uv || edges[e].vu)) {
        int a = block[edges[e].u], b = block[edges[e].v]; if (a > b) { int t = a; a = b; b = t; }
        has[a][b] = 1;
        if (tags[edges[e].u] != tags[edges[e].v]) score[a][b] += (edges[e].uv > 0) + (edges[e].vu > 0);
    }
    int pair_a[6], pair_b[6], pair_score[6], pair_count = 0;
    for (int a = 0; a < blocks; ++a) for (int b = a + 1; b < blocks; ++b) if (has[a][b]) {
        int pos = pair_count++;
        while (pos > 0 && (pair_score[pos - 1] < score[a][b] ||
               (pair_score[pos - 1] == score[a][b] && (pair_a[pos - 1] > a || (pair_a[pos - 1] == a && pair_b[pos - 1] > b)))) {
            pair_a[pos] = pair_a[pos - 1]; pair_b[pos] = pair_b[pos - 1]; pair_score[pos] = pair_score[pos - 1]; --pos;
        }
        pair_a[pos] = a; pair_b[pos] = b; pair_score[pos] = score[a][b];
    }
    int parent[4] = {0, 1, 2, 3};
    for (int i = 0; i < pair_count; ++i) {
        int a = merge_find(parent, pair_a[i]), b = merge_find(parent, pair_b[i]);
        if (a == b) continue;
        int root = a < b ? a : b, other = a < b ? b : a; parent[other] = root;
        int active[MERGE_NMAX] = {0};
        for (int v = 0; v < n; ++v) active[v] = merge_find(parent, block[v]) == root;
        flow[root] = merge_component_flow(n, active, source_caps, sink_caps, edges, m);
        if (flow[root] < 0) return -1;
        flow[other] = 0;
    }
    int64_t answer = 0;
    for (int b = 0; b < blocks; ++b) if (merge_find(parent, b) == b) answer += flow[b];
    return answer;
}
