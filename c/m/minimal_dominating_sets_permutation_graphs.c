#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_PARSEABLE_LENGTH = 10, MAX_STATES = 59049 };

typedef struct {
    int n;
    int top[MAX_N];
    int top_vertex[MAX_N];
    unsigned char adj[MAX_N][MAX_N];
    int64_t ways[MAX_STATES];
} Context;

static int graph_case(const Context *c, int i, int j, int k) {
    int a = c->top[i], b = c->top[j], d = c->top[k];
    if (a < b && b < d) return 1;
    if (a < d && d < b) return 2;
    if (b < a && a < d) return 3;
    if (b < d && d < a) return 4;
    if (d < a && a < b) return 5;
    return 0;
}

static int dominated(const Context *c, int y, const int *selected, int count) {
    for (int z = 0; z < count; ++z) if (c->adj[selected[z]][y]) return 1;
    return 0;
}

static int irredundant(const Context *c, const int *selected, int count) {
    for (int x = 0; x < count; ++x) {
        int has_private = 0;
        for (int y = 0; y < c->n && !has_private; ++y) {
            if (!c->adj[selected[x]][y]) continue;
            int shared = 0;
            for (int z = 0; z < count; ++z)
                if (z != x && c->adj[selected[z]][y]) { shared = 1; break; }
            if (!shared) has_private = 1;
        }
        if (!has_private) return 0;
    }
    return 1;
}

static int private_min_rank(const Context *c, int x, const int *selected, int count) {
    int best = -1;
    for (int y = 0; y < c->n; ++y) {
        if (!c->adj[x][y]) continue;
        int shared = 0;
        for (int z = 0; z < count; ++z)
            if (selected[z] != x && c->adj[selected[z]][y]) { shared = 1; break; }
        if (!shared && (best < 0 || c->top[y] < c->top[best])) best = y;
    }
    return best;
}

static int initial(const Context *c, int i, int j, int k, int r, int s) {
    int n = c->n, triple[3] = {i, j, k};
    if (r != n || !irredundant(c, triple, 3)) return 0;
    int which = graph_case(c, i, j, k);
    if (which == 1) {
        for (int y = 0; y < n; ++y)
            if (y < i && c->top[y] < c->top[i]) return 0;
        return s == private_min_rank(c, i, triple, 3);
    }
    if (which == 2) {
        if (s != n) return 0;
        for (int y = 0; y < n; ++y)
            if (c->top[y] < c->top[k] && y < j && !dominated(c, y, triple, 3)) return 0;
        return 1;
    }
    if (which == 3) {
        for (int y = 0; y < n; ++y)
            if (c->top[y] < c->top[j] && y < i) return 0;
        return s == private_min_rank(c, j, triple, 3);
    }
    if (which == 4) {
        if (s != n) return 0;
        for (int y = 0; y < n; ++y)
            if (c->top[y] < c->top[j] && y < i && !dominated(c, y, triple, 3)) return 0;
        return 1;
    }
    if (which == 5) {
        for (int y = 0; y < n; ++y)
            if (c->top[y] < c->top[k] && y < i) return 0;
        return s == private_min_rank(c, k, triple, 3);
    }
    return 0;
}

static int regular(const Context *c, int i, int j, int k, int r, int s) {
    int n = c->n, triple[3] = {i, j, k};
    if (!irredundant(c, triple, 3)) return 0;
    int which = graph_case(c, i, j, k);
    if (which >= 1 && which <= 4) {
        if (r < 0 || r >= i) return 0;
    } else if (which == 5) {
        if (r != n) return 0;
    } else return 0;
    if (which == 2 || which == 4) return s == n;
    if (s < 0 || s >= n) return 0;
    if (which == 1)
        return c->adj[i][s] && !c->adj[r][s] && !c->adj[j][s] && !c->adj[k][s];
    if (which == 3)
        return c->adj[j][s] && !c->adj[r][s] && !c->adj[i][s] && !c->adj[k][s];
    return c->adj[k][s] && !c->adj[i][s] && !c->adj[j][s];
}

static int is_final(const Context *c, int i, int j, int k, int r) {
    int selected[4], count = 0;
    if (r != c->n) selected[count++] = r;
    selected[count++] = i; selected[count++] = j; selected[count++] = k;
    for (int y = 0; y < c->n; ++y)
        if (i < y && c->top[i] < c->top[y] && !dominated(c, y, selected, count)) return 0;
    return 1;
}

static size_t state_index(int i, int j, int k, int r, int s, int base) {
    return (((((size_t)i * (size_t)base + (size_t)j) * (size_t)base + (size_t)k)
             * (size_t)base + (size_t)r) * (size_t)base + (size_t)s);
}

static int successor(const Context *c, int i, int j, int k, int r, int s, int ell,
                     int *out_r, int *out_s) {
    int n = c->n, which = graph_case(c, j, k, ell);
    if (!which) return 0;
    int selected[5], count = 0;
    if (r != n) selected[count++] = r;
    selected[count++] = i; selected[count++] = j; selected[count++] = k; selected[count++] = ell;
    if (!irredundant(c, selected, count)) return 0;
    if (s != n && c->top[ell] <= c->top[s]) return 0;
    if (!c->adj[j][k]) {
        for (int y = 0; y < n; ++y)
            if (i < y && y < j && c->top[i] < c->top[y] && c->top[y] < c->top[j]
                && !dominated(c, y, selected, count)) return 0;
    }
    if (c->adj[i][k]) {
        for (int y = 0; y < n; ++y)
            if (j < y && y < k && c->top[j] < c->top[y] && c->top[y] < c->top[ell]
                && !dominated(c, y, selected, count)) return 0;
    }
    if (which == 5) *out_r = n;
    else {
        int max_rank = c->top[i];
        if (r != n && c->top[r] > max_rank) max_rank = c->top[r];
        *out_r = c->top_vertex[max_rank];
    }
    if (which == 2 || which == 4) *out_s = n;
    else if (s != n &&
             ((c->top[i] < c->top[j] && c->top[i] < c->top[k]) ||
              (c->top[j] < c->top[i] && c->top[j] < c->top[k]) ||
              (c->top[k] < c->top[i] && c->top[k] < c->top[j])) ==
             ((c->top[j] < c->top[k] && c->top[j] < c->top[ell]) ||
              (c->top[k] < c->top[j] && c->top[k] < c->top[ell]) ||
              (c->top[ell] < c->top[j] && c->top[ell] < c->top[k]))) {
        *out_s = s;
    } else {
        int y = j;
        if (c->top[k] < c->top[y]) y = k;
        if (c->top[ell] < c->top[y]) y = ell;
        *out_s = private_min_rank(c, y, selected, count);
        if (*out_s < 0) return 0;
    }
    return regular(c, j, k, ell, *out_r, *out_s);
}

static int dominates_mask(uint32_t mask, const uint32_t *neighborhood, int n) {
    uint32_t cover = 0;
    for (int x = 0; x < n; ++x) if (mask & (1u << x)) cover |= neighborhood[x];
    return cover == ((1u << n) - 1u);
}

static int minimal_small(uint32_t mask, const uint32_t *neighborhood, int n) {
    if (!dominates_mask(mask, neighborhood, n)) return 0;
    for (int x = 0; x < n; ++x)
        if ((mask & (1u << x)) && dominates_mask(mask ^ (1u << x), neighborhood, n)) return 0;
    return 1;
}

int64_t minimal_dominating_sets_permutation_graphs(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    int n = (int)input[0];
    if (length != (size_t)n + 1u) return -1;
    Context c = {0};
    c.n = n;
    for (int x = 0; x < n; ++x) {
        int64_t rank = input[x + 1];
        if (rank < 0 || rank >= n) return -1;
        c.top[x] = (int)rank;
        for (int y = 0; y < x; ++y) if (c.top[y] == c.top[x]) return -1;
        c.top_vertex[c.top[x]] = x;
        c.adj[x][x] = 1;
    }
    for (int x = 0; x < n; ++x)
        for (int y = x + 1; y < n; ++y)
            c.adj[x][y] = c.adj[y][x] = (unsigned char)(c.top[x] > c.top[y]);

    int base = n + 1;
    int64_t total = 0;
    for (int i = n - 3; i >= 0; --i) {
        for (int j = i + 1; j < n - 1; ++j) {
            for (int k = j + 1; k < n; ++k) {
                int triple[3] = {i, j, k};
                if (!graph_case(&c, i, j, k) || !irredundant(&c, triple, 3)) continue;
                for (int ri = 0; ri <= i; ++ri) {
                    int r = ri == i ? n : ri;
                    for (int s = 0; s <= n; ++s) {
                        if (!initial(&c, i, j, k, r, s) && !regular(&c, i, j, k, r, s)) continue;
                        int64_t count = is_final(&c, i, j, k, r) ? 1 : 0;
                        for (int ell = k + 1; ell < n; ++ell) {
                            int nr, ns;
                            if (successor(&c, i, j, k, r, s, ell, &nr, &ns))
                                count += c.ways[state_index(j, k, ell, nr, ns, base)];
                        }
                        c.ways[state_index(i, j, k, r, s, base)] = count;
                        if (initial(&c, i, j, k, r, s)) total += count;
                    }
                }
            }
        }
    }
    uint32_t neighborhoods[MAX_N] = {0};
    for (int x = 0; x < n; ++x)
        for (int y = 0; y < n; ++y) if (c.adj[x][y]) neighborhoods[x] |= 1u << y;
    uint32_t full = (1u << n) - 1u;
    for (uint32_t mask = 1; mask <= full; ++mask) {
        int size = 0;
        for (uint32_t bits = mask; bits; bits >>= 1) size += (int)(bits & 1u);
        if (size <= 2 && minimal_small(mask, neighborhoods, n)) ++total;
    }
    return total;
}
