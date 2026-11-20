/* Maximum-weight general matching with primal-dual odd-cycle contraction. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MW_N 64
#define MW_ID (2 * MW_N)
#define MW_SLOTS (MW_ID + 1)
#define MW_INFINITY INT64_MAX

typedef struct {
    int n, nodes;
    int64_t w[MW_SLOTS][MW_SLOTS];
    int64_t label[MW_SLOTS];
    int16_t edge_u[MW_SLOTS][MW_SLOTS], edge_v[MW_SLOTS][MW_SLOTS];
    int16_t mate[MW_SLOTS], slack[MW_SLOTS], rep[MW_SLOTS], parent[MW_SLOTS];
    int16_t state[MW_SLOTS];
    int32_t seen[MW_SLOTS];
    int16_t child[MW_SLOTS][MW_SLOTS], child_count[MW_SLOTS];
    int16_t from[MW_SLOTS][MW_N + 1];
    int16_t queue[MW_N];
    uint8_t queued[MW_N + 1];
    int q_head, q_tail, q_count, epoch;
} MWMatcher;

static int64_t mw_delta(const MWMatcher *m, int a, int b) {
    return m->label[m->edge_u[a][b]] + m->label[m->edge_v[a][b]] - 2 * m->w[a][b];
}

static void mw_enqueue_leaf(MWMatcher *m, int v) {
    if (v < 1 || v > m->n || m->queued[v]) return;
    m->queue[m->q_tail] = (int16_t)v;
    m->q_tail = (m->q_tail + 1) % m->n;
    ++m->q_count;
    m->queued[v] = 1;
}

static void mw_enqueue_members(MWMatcher *m, int x) {
    if (x <= m->n) {
        mw_enqueue_leaf(m, x);
        return;
    }
    for (int i = 0; i < m->child_count[x]; ++i)
        mw_enqueue_members(m, m->child[x][i]);
}

static void mw_set_rep(MWMatcher *m, int x, int b) {
    m->rep[x] = (int16_t)b;
    if (x > m->n)
        for (int i = 0; i < m->child_count[x]; ++i)
            mw_set_rep(m, m->child[x][i], b);
}

static void mw_update_slack(MWMatcher *m, int u, int x) {
    int old = m->slack[x];
    if (old == 0 || mw_delta(m, u, x) < mw_delta(m, old, x))
        m->slack[x] = (int16_t)u;
}

static void mw_refresh_slack(MWMatcher *m, int x) {
    m->slack[x] = 0;
    for (int u = 1; u <= m->n; ++u)
        if (m->w[u][x] > 0 && m->rep[u] != x && m->state[m->rep[u]] == 0)
            mw_update_slack(m, u, x);
}

static int mw_cycle_position(MWMatcher *m, int b, int x) {
    int pos = 0;
    while (pos < m->child_count[b] && m->child[b][pos] != x) ++pos;
    if (pos >= m->child_count[b]) return 0;
    if (pos & 1) {
        for (int left = 1, right = m->child_count[b] - 1; left < right; ++left, --right) {
            int16_t tmp = m->child[b][left];
            m->child[b][left] = m->child[b][right];
            m->child[b][right] = tmp;
        }
        pos = m->child_count[b] - pos;
    }
    return pos;
}

static void mw_rotate_cycle(MWMatcher *m, int b, int start) {
    int count = m->child_count[b];
    int16_t saved[MW_SLOTS];
    for (int i = 0; i < count; ++i) saved[i] = m->child[b][(i + start) % count];
    for (int i = 0; i < count; ++i) m->child[b][i] = saved[i];
}

static void mw_set_pair(MWMatcher *m, int u, int v) {
    m->mate[u] = m->edge_v[u][v];
    if (u <= m->n) return;
    int leaf = m->edge_u[u][v];
    int entry = m->from[u][leaf];
    int pos = mw_cycle_position(m, u, entry);
    for (int i = 0; i < pos; i += 1)
        mw_set_pair(m, m->child[u][i], m->child[u][i ^ 1]);
    mw_set_pair(m, entry, v);
    mw_rotate_cycle(m, u, pos);
}

static void mw_augment(MWMatcher *m, int u, int v) {
    for (;;) {
        int next = m->rep[m->mate[u]];
        mw_set_pair(m, u, v);
        if (next == 0) return;
        int prior = m->rep[m->parent[next]];
        mw_set_pair(m, next, prior);
        u = prior;
        v = next;
    }
}

static int mw_lca(MWMatcher *m, int u, int v) {
    ++m->epoch;
    for (;;) {
        if (u != 0) {
            if (m->seen[u] == m->epoch) return u;
            m->seen[u] = m->epoch;
            u = m->rep[m->mate[u]];
            if (u != 0) u = m->rep[m->parent[u]];
        }
        int tmp = u; u = v; v = tmp;
        if (u == 0 && v == 0) return 0;
    }
}

static int mw_add_child(MWMatcher *m, int b, int x) {
    int at = m->child_count[b]++;
    m->child[b][at] = (int16_t)x;
    return at;
}

static void mw_contract(MWMatcher *m, int u, int base, int v) {
    int b = m->n + 1;
    while (b <= m->nodes && m->rep[b] != 0) ++b;
    if (b > m->nodes) ++m->nodes;

    m->label[b] = 0;
    m->state[b] = 0;
    m->mate[b] = m->mate[base];
    m->child_count[b] = 0;
    mw_add_child(m, b, base);
    for (int x = u, y; x != base; x = m->rep[m->parent[y]]) {
        mw_add_child(m, b, x);
        y = m->rep[m->mate[x]];
        mw_add_child(m, b, y);
        mw_enqueue_members(m, y);
    }
    for (int left = 1, right = m->child_count[b] - 1; left < right; ++left, --right) {
        int16_t tmp = m->child[b][left];
        m->child[b][left] = m->child[b][right];
        m->child[b][right] = tmp;
    }
    for (int x = v, y; x != base; x = m->rep[m->parent[y]]) {
        mw_add_child(m, b, x);
        y = m->rep[m->mate[x]];
        mw_add_child(m, b, y);
        mw_enqueue_members(m, y);
    }

    mw_set_rep(m, b, b);
    for (int x = 1; x <= m->nodes; ++x) {
        m->w[b][x] = m->w[x][b] = 0;
        m->edge_u[b][x] = m->edge_v[b][x] = 0;
        m->edge_u[x][b] = m->edge_v[x][b] = 0;
    }
    for (int leaf = 1; leaf <= m->n; ++leaf) m->from[b][leaf] = 0;

    for (int i = 0; i < m->child_count[b]; ++i) {
        int x = m->child[b][i];
        for (int y = 1; y <= m->nodes; ++y) {
            if (m->w[x][y] == 0) continue;
            if (m->w[b][y] == 0 || mw_delta(m, x, y) < mw_delta(m, b, y)) {
                m->w[b][y] = m->w[x][y];
                m->edge_u[b][y] = m->edge_u[x][y];
                m->edge_v[b][y] = m->edge_v[x][y];
                m->w[y][b] = m->w[y][x];
                m->edge_u[y][b] = m->edge_u[y][x];
                m->edge_v[y][b] = m->edge_v[y][x];
            }
        }
        for (int leaf = 1; leaf <= m->n; ++leaf)
            if (x <= m->n ? x == leaf : m->from[x][leaf] != 0)
                m->from[b][leaf] = (int16_t)x;
    }
    mw_refresh_slack(m, b);
}

static void mw_expand(MWMatcher *m, int b) {
    for (int i = 0; i < m->child_count[b]; ++i)
        mw_set_rep(m, m->child[b][i], m->child[b][i]);
    int outside = m->parent[b];
    int entry_leaf = m->edge_u[b][outside];
    int entry = m->from[b][entry_leaf];
    int pos = mw_cycle_position(m, b, entry);
    for (int i = 0; i < pos; i += 2) {
        int xs = m->child[b][i], xns = m->child[b][i + 1];
        m->parent[xs] = m->edge_u[xns][xs];
        m->state[xs] = 1;
        m->state[xns] = 0;
        m->slack[xs] = 0;
        mw_refresh_slack(m, xns);
        mw_enqueue_members(m, xns);
    }
    m->state[entry] = 1;
    m->parent[entry] = (int16_t)outside;
    for (int i = pos + 1; i < m->child_count[b]; ++i) {
        int x = m->child[b][i];
        m->state[x] = -1;
        mw_refresh_slack(m, x);
    }
    m->rep[b] = 0;
}

static int mw_process_edge(MWMatcher *m, int left, int right) {
    int u = m->rep[left], v = m->rep[right];
    if (m->state[v] == -1) {
        m->parent[v] = (int16_t)left;
        m->state[v] = 1;
        int next = m->rep[m->mate[v]];
        m->slack[v] = 0;
        m->slack[next] = 0;
        m->state[next] = 0;
        mw_enqueue_members(m, next);
    } else if (m->state[v] == 0) {
        int base = mw_lca(m, u, v);
        if (base == 0) {
            mw_augment(m, u, v);
            mw_augment(m, v, u);
            return 1;
        }
        mw_contract(m, u, base, v);
    }
    return 0;
}

static int mw_stage(MWMatcher *m) {
    for (int x = 0; x <= m->nodes; ++x) {
        m->state[x] = -1;
        m->slack[x] = 0;
    }
    m->q_head = m->q_tail = m->q_count = 0;
    memset(m->queued, 0, sizeof(m->queued));
    for (int x = 1; x <= m->nodes; ++x)
        if (m->rep[x] == x && m->mate[x] == 0) {
            m->parent[x] = 0;
            m->state[x] = 0;
            mw_enqueue_members(m, x);
        }
    if (m->q_count == 0) return 0;

    for (;;) {
        while (m->q_count != 0) {
            int u = m->queue[m->q_head];
            m->q_head = (m->q_head + 1) % m->n;
            --m->q_count;
            m->queued[u] = 0;
            if (m->state[m->rep[u]] == 1) continue;
            for (int v = 1; v <= m->n; ++v) {
                if (m->w[u][v] == 0 || m->rep[u] == m->rep[v]) continue;
                if (mw_delta(m, u, v) == 0) {
                    if (mw_process_edge(m, m->edge_u[u][v], m->edge_v[u][v])) return 1;
                } else {
                    mw_update_slack(m, u, m->rep[v]);
                }
            }
        }

        int64_t step = MW_INFINITY;
        for (int u = 1; u <= m->n; ++u)
            if (m->state[m->rep[u]] == 0 && m->label[u] < step) step = m->label[u];
        for (int b = m->n + 1; b <= m->nodes; ++b)
            if (m->rep[b] == b && m->state[b] == 1 && m->label[b] / 2 < step)
                step = m->label[b] / 2;
        for (int x = 1; x <= m->nodes; ++x) {
            if (m->rep[x] != x || m->slack[x] == 0) continue;
            int64_t candidate = mw_delta(m, m->slack[x], x);
            if (m->state[x] == -1 && candidate < step) step = candidate;
            else if (m->state[x] == 0 && candidate / 2 < step) step = candidate / 2;
        }
        if (step == MW_INFINITY) return 0;

        for (int u = 1; u <= m->n; ++u) {
            if (m->state[m->rep[u]] == 0) {
                if (m->label[u] == step) return 0;
                m->label[u] -= step;
            } else if (m->state[m->rep[u]] == 1) {
                m->label[u] += step;
            }
        }
        for (int b = m->n + 1; b <= m->nodes; ++b) {
            if (m->rep[b] != b) continue;
            if (m->state[b] == 0) m->label[b] += 2 * step;
            else if (m->state[b] == 1) m->label[b] -= 2 * step;
        }

        for (int x = 1; x <= m->nodes; ++x) {
            if (m->rep[x] == x && m->slack[x] != 0 && m->rep[m->slack[x]] != x &&
                mw_delta(m, m->slack[x], x) == 0) {
                int source = m->slack[x];
                if (mw_process_edge(m, m->edge_u[source][x], m->edge_v[source][x])) return 1;
            }
        }
        for (int b = m->n + 1; b <= m->nodes; ++b)
            if (m->rep[b] == b && m->state[b] == 1 && m->label[b] == 0)
                mw_expand(m, b);
    }
}

int64_t general_weighted_matching_primal_dual_blossom(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 6051) return -2;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MW_N || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2) return -2;
    int n = (int)n_value, edges = (int)m_value;
    if (length != (size_t)(2 + 3 * edges)) return -2;

    MWMatcher m;
    memset(&m, 0, sizeof(m));
    m.n = n;
    m.nodes = n;
    int64_t greatest = 0;
    for (int i = 0; i < edges; ++i) {
        int64_t uv = input[2 + 3 * i], vv = input[3 + 3 * i], wt = input[4 + 3 * i];
        if (uv < 0 || uv >= n || vv < 0 || vv >= n || uv == vv || wt < 1 || wt > 1000000)
            return -2;
        int u = (int)uv + 1, v = (int)vv + 1;
        if (m.w[u][v] != 0) return -2;
        m.w[u][v] = m.w[v][u] = wt;
        m.edge_u[u][v] = (int16_t)u; m.edge_v[u][v] = (int16_t)v;
        m.edge_u[v][u] = (int16_t)v; m.edge_v[v][u] = (int16_t)u;
        if (wt > greatest) greatest = wt;
    }
    for (int i = 1; i <= n; ++i) {
        m.rep[i] = (int16_t)i;
        m.label[i] = greatest;
        m.from[i][i] = (int16_t)i;
    }
    while (mw_stage(&m)) { }
    int64_t answer = 0;
    for (int i = 1; i <= n; ++i)
        if (m.mate[i] > i) answer += m.w[i][m.mate[i]];
    return answer;
}
