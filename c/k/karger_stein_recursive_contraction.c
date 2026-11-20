/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    int n, m, u[32], v[32];
    const int64_t *tape;
    size_t count, position;
} KsInput;

static int ks_root(const int parent[12], int v) {
    while (parent[v] != v) v = parent[v];
    return v;
}

static int ks_solve(KsInput *in, const int parent[12], int components) {
    if (components <= 6) {
        int roots[6], index[12], used = 0;
        for (int i = 0; i < in->n; ++i)
            if (parent[i] == i) roots[used++] = i;
        for (int i = 0; i < used; ++i) index[roots[i]] = i;
        int best = in->m + 1;
        /* Pin component zero to one side and omit the full set. */
        for (unsigned mask = 0; mask < ((1u << (components - 1)) - 1); ++mask) {
            unsigned side = (mask << 1) | 1u;
            int cut = 0;
            for (int e = 0; e < in->m; ++e) {
                int a = index[ks_root(parent, in->u[e])];
                int b = index[ks_root(parent, in->v[e])];
                cut += ((side >> a) & 1u) != ((side >> b) & 1u);
            }
            if (cut < best) best = cut;
        }
        return best;
    }
    static const int target[13] = {0,0,0,0,0,0,0,6,7,8,9,9,10};
    int best = in->m + 1;
    for (int branch = 0; branch < 2; ++branch) {
        int next[12];
        memcpy(next, parent, sizeof(next));
        for (int remaining = components; remaining > target[components]; --remaining) {
            int live = 0;
            for (int e = 0; e < in->m; ++e)
                if (ks_root(next, in->u[e]) != ks_root(next, in->v[e])) ++live;
            if (in->position >= in->count) return -1;
            int64_t rank = in->tape[in->position++];
            if (rank < 0 || rank >= live) return -1;
            for (int e = 0; e < in->m; ++e) {
                int a = ks_root(next, in->u[e]), b = ks_root(next, in->v[e]);
                if (a == b) continue;
                if (rank-- == 0) { next[b] = a; break; }
            }
        }
        int result = ks_solve(in, next, target[components]);
        if (result < 0) return -1;
        if (result < best) best = result;
    }
    return best;
}

int64_t karger_stein_recursive_contraction(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > 132) return -1;
    if (input[0] < 2 || input[0] > 12 || input[1] < 1 || input[1] > 32
        || input[2] < 0 || input[2] > 64) return -1;
    KsInput in = {0};
    in.n = (int)input[0]; in.m = (int)input[1]; in.count = (size_t)input[2];
    if (length != 3 + 2 * (size_t)in.m + in.count) return -1;
    int parent[12];
    for (int i = 0; i < 12; ++i) parent[i] = i;
    for (int i = 0; i < in.m; ++i) {
        int64_t u = input[3 + 2*i], v = input[4 + 2*i];
        if (u < 0 || v < 0 || u >= in.n || v >= in.n || u == v) return -1;
        in.u[i] = (int)u; in.v[i] = (int)v;
        parent[ks_root(parent, (int)v)] = ks_root(parent, (int)u);
    }
    int first = ks_root(parent, 0);
    for (int i = 1; i < in.n; ++i) if (ks_root(parent, i) != first) return -1;
    for (int i = 0; i < 12; ++i) parent[i] = i;
    in.tape = input + 3 + 2*in.m;
    int result = ks_solve(&in, parent, in.n);
    return result < 0 || in.position != in.count ? -1 : result;
}
