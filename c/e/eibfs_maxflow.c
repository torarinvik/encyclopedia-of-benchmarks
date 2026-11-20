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
