#include <stddef.h>
#include <stdint.h>

enum { PTS_MAX_N = 16, PTS_MAX_Q = 32, PTS_BASE = 16,
       PTS_MAX_INPUT = 5 * PTS_MAX_N + 4 * PTS_MAX_Q - 2 };
static const int64_t PTS_MOD = INT64_C(998244353);

static size_t pts_find(size_t parent[PTS_MAX_N], size_t x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
static int64_t pts_norm(int64_t x) { x %= PTS_MOD; return x < 0 ? x + PTS_MOD : x; }
static void pts_compose(int64_t lm, int64_t la, int64_t rm, int64_t ra,
                        int64_t *m, int64_t *a) {
    *m = lm * rm % PTS_MOD;
    *a = (lm * ra + la) % PTS_MOD;
}
static void pts_store(uint8_t *out, size_t at, int64_t x) {
    uint64_t bits = (uint64_t)x;
    for (size_t i = 0; i < 8; ++i) out[at + i] = (uint8_t)(bits >> (8 * i));
}

int64_t point_set_tree_path_composite_sum_fixed_root(const int64_t *input, size_t length,
                                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > PTS_MAX_INPUT) return -1;
    int64_t nv = input[0], qv = input[1];
    if (nv < 1 || nv > PTS_MAX_N || qv < 1 || qv > PTS_MAX_Q) return -1;
    size_t n = (size_t)nv, q = (size_t)qv, cursor = 2;
    int64_t value[PTS_MAX_N] = {0};
    for (size_t u = 0; u < n; ++u) {
        if (cursor >= length) return -1;
        value[u] = input[cursor++];
        if (value[u] < 0 || value[u] >= PTS_MOD) return -1;
    }
    int edge_at[PTS_MAX_N][PTS_MAX_N];
    for (size_t u = 0; u < PTS_MAX_N; ++u)
        for (size_t v = 0; v < PTS_MAX_N; ++v) edge_at[u][v] = -1;
    int64_t eu[PTS_MAX_N - 1], ev[PTS_MAX_N - 1];
    int64_t eb[PTS_MAX_N - 1], ec[PTS_MAX_N - 1];
    size_t dsu[PTS_MAX_N], dsz[PTS_MAX_N];
    for (size_t u = 0; u < n; ++u) { dsu[u] = u; dsz[u] = 1; }
    for (size_t e = 0; e + 1 < n; ++e) {
        if (cursor + 4 > length) return -1;
        int64_t ur = input[cursor++], vr = input[cursor++];
        eb[e] = input[cursor++]; ec[e] = input[cursor++];
        if (ur < 0 || ur >= nv || vr < 0 || vr >= nv || ur == vr ||
            eb[e] < 1 || eb[e] >= PTS_MOD || ec[e] < 0 || ec[e] >= PTS_MOD) return -1;
        size_t u = (size_t)ur, v = (size_t)vr, ru = pts_find(dsu, u), rv = pts_find(dsu, v);
        if (ru == rv) return -1;
        if (dsz[ru] < dsz[rv]) { size_t t = ru; ru = rv; rv = t; }
        dsu[rv] = ru; dsz[ru] += dsz[rv];
        eu[e] = ur; ev[e] = vr; edge_at[u][v] = edge_at[v][u] = (int)e;
    }
    int64_t op_kind[PTS_MAX_Q], op_x[PTS_MAX_Q], op_y[PTS_MAX_Q], op_z[PTS_MAX_Q];
    for (size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        int64_t kind = input[cursor++]; op_kind[i] = kind;
        if (kind == 0) {
            if (cursor + 2 > length) return -1;
            op_x[i] = input[cursor++]; op_y[i] = input[cursor++]; op_z[i] = 0;
            if (op_x[i] < 0 || op_x[i] >= nv || op_y[i] < 0 || op_y[i] >= PTS_MOD) return -1;
        } else if (kind == 1) {
            if (cursor + 3 > length) return -1;
            op_x[i] = input[cursor++]; op_y[i] = input[cursor++]; op_z[i] = input[cursor++];
            if (op_x[i] < 0 || op_x[i] >= nv - 1 || op_y[i] < 1 || op_y[i] >= PTS_MOD ||
                op_z[i] < 0 || op_z[i] >= PTS_MOD) return -1;
        } else return -1;
    }
    if (cursor != length) return -1;
    size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;

    int64_t parent[PTS_MAX_N], parent_edge[PTS_MAX_N], depth[PTS_MAX_N];
    size_t order[PTS_MAX_N], stack[PTS_MAX_N], count = 0, top = 0;
    for (size_t u = 0; u < n; ++u) { parent[u] = -2; parent_edge[u] = -1; depth[u] = 0; }
    parent[0] = -1; stack[top++] = 0;
    while (top) {
        size_t u = stack[--top]; order[count++] = u;
        for (size_t v = 0; v < n; ++v) if (edge_at[u][v] >= 0 && (int64_t)v != parent[u]) {
            parent[v] = (int64_t)u; parent_edge[v] = edge_at[u][v]; depth[v] = depth[u] + 1;
            stack[top++] = v;
        }
    }
    size_t sub[PTS_MAX_N]; int64_t heavy[PTS_MAX_N];
    for (size_t u = 0; u < n; ++u) { sub[u] = 1; heavy[u] = -1; }
    for (size_t i = count; i > 0; --i) {
        size_t u = order[i - 1], best = 0;
        for (size_t v = 0; v < n; ++v) if (parent[v] == (int64_t)u) {
            sub[u] += sub[v];
            if (sub[v] > best || (sub[v] == best && (heavy[u] < 0 || v < (size_t)heavy[u]))) {
                best = sub[v]; heavy[u] = (int64_t)v;
            }
        }
    }
    size_t head[PTS_MAX_N], pos[PTS_MAX_N], chain_end[PTS_MAX_N], chain_stack[PTS_MAX_N];
    size_t timer = 0; top = 0; chain_stack[top++] = 0;
    while (top) {
        size_t h = chain_stack[--top], u = h;
        do {
            head[u] = h; pos[u] = timer++;
            for (size_t v = 0; v < n; ++v)
                if (parent[v] == (int64_t)u && (int64_t)v != heavy[u]) chain_stack[top++] = v;
            u = heavy[u] < 0 ? n : (size_t)heavy[u];
        } while (u < n);
        chain_end[h] = timer;
    }
    int64_t down[PTS_MAX_N] = {0};
    for (size_t i = count; i > 0; --i) {
        size_t u = order[i - 1]; int64_t total = value[u];
        for (size_t v = 0; v < n; ++v) if (parent[v] == (int64_t)u) {
            size_t e = (size_t)parent_edge[v];
            total += eb[e] * down[v] + ec[e] * (int64_t)sub[v];
        }
        down[u] = pts_norm(total);
    }
    int64_t lm[PTS_MAX_N] = {0}, la[PTS_MAX_N] = {0};
    for (size_t u = 0; u < n; ++u) {
        la[u] = value[u];
        for (size_t v = 0; v < n; ++v) if (parent[v] == (int64_t)u) {
            size_t e = (size_t)parent_edge[v];
            if ((int64_t)v == heavy[u]) { lm[u] = eb[e]; la[u] += ec[e] * (int64_t)sub[v]; }
            else la[u] += eb[e] * down[v] + ec[e] * (int64_t)sub[v];
        }
        la[u] = pts_norm(la[u]);
    }
    int64_t tm[2 * PTS_BASE], ta[2 * PTS_BASE];
    for (size_t i = 0; i < 2 * PTS_BASE; ++i) { tm[i] = 1; ta[i] = 0; }
    for (size_t u = 0; u < n; ++u) { tm[PTS_BASE + pos[u]] = lm[u]; ta[PTS_BASE + pos[u]] = la[u]; }
    for (size_t i = PTS_BASE - 1; i > 0; --i)
        pts_compose(tm[2 * i], ta[2 * i], tm[2 * i + 1], ta[2 * i + 1], &tm[i], &ta[i]);
#define PTS_SET_LEAF(vertex) do { \
    size_t node = PTS_BASE + pos[(vertex)]; tm[node] = lm[(vertex)]; ta[node] = la[(vertex)]; \
    while ((node /= 2) != 0) pts_compose(tm[2 * node], ta[2 * node], tm[2 * node + 1], ta[2 * node + 1], &tm[node], &ta[node]); \
} while (0)
    int64_t current[PTS_MAX_N] = {0};
    for (size_t u = 0; u < n; ++u) if (head[u] == u) current[u] = down[u];
    int64_t answers[PTS_MAX_Q] = {0};
    for (size_t qi = 0; qi < q; ++qi) {
        size_t start;
        if (op_kind[qi] == 0) {
            size_t u = (size_t)op_x[qi];
            la[u] = pts_norm(la[u] + op_y[qi] - value[u]); value[u] = op_y[qi];
            PTS_SET_LEAF(u); start = u;
        } else {
            size_t e = (size_t)op_x[qi], u = (size_t)eu[e], v = (size_t)ev[e];
            size_t child = parent[u] == (int64_t)v ? u : v, p = (size_t)parent[child];
            int64_t oldb = eb[e], oldc = ec[e], newb = op_y[qi], newc = op_z[qi];
            if (heavy[p] == (int64_t)child) {
                lm[p] = newb; la[p] = pts_norm(la[p] + (newc - oldc) * (int64_t)sub[child]);
            } else {
                la[p] = pts_norm(la[p] + (newb - oldb) * current[child]
                                  + (newc - oldc) * (int64_t)sub[child]);
            }
            eb[e] = newb; ec[e] = newc; PTS_SET_LEAF(p); start = p;
        }
        size_t u = start;
        while (1) {
            size_t h = head[u]; int64_t previous = current[h];
            size_t left = PTS_BASE + pos[h], right = PTS_BASE + chain_end[h];
            int64_t l_m = 1, l_a = 0, r_m = 1, r_a = 0;
            while (left < right) {
                if (left & 1) { int64_t m, a; pts_compose(l_m, l_a, tm[left], ta[left], &m, &a); l_m = m; l_a = a; ++left; }
                if (right & 1) { --right; int64_t m, a; pts_compose(tm[right], ta[right], r_m, r_a, &m, &a); r_m = m; r_a = a; }
                left /= 2; right /= 2;
            }
            int64_t cm, ca; pts_compose(l_m, l_a, r_m, r_a, &cm, &ca);
            current[h] = ca;
            if (h == 0) break;
            size_t p = (size_t)parent[h], e = (size_t)parent_edge[h];
            la[p] = pts_norm(la[p] + eb[e] * (current[h] - previous)); PTS_SET_LEAF(p); u = p;
        }
        answers[qi] = current[0];
    }
    for (size_t i = 0; i < q; ++i) pts_store(output, 8 * i, answers[i]);
    return (int64_t)required;
}
