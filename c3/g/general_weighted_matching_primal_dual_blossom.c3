module general_weighted_matching_primal_dual_blossom;

const usz MAX_N = 64;
const usz IDS = 128;
const usz SLOTS = 129;
const long INF = 9223372036854775807;

struct Matcher {
    usz n; usz nodes; int epoch;
    long[SLOTS][SLOTS] weight; long[SLOTS] dual;
    short[SLOTS][SLOTS] edge_a; short[SLOTS][SLOTS] edge_b;
    short[SLOTS] mate; short[SLOTS] slack_from; short[SLOTS] top; short[SLOTS] parent;
    short[SLOTS] state; int[SLOTS] seen;
    short[SLOTS][SLOTS] members; short[SLOTS] member_count;
    short[SLOTS][65] child_of;
    usz[64] queue; bool[65] queued;
    usz head; usz tail; usz count;
}

fn long delta(Matcher* m, usz a, usz b) {
    return m->dual[(usz)m->edge_a[a][b]] + m->dual[(usz)m->edge_b[a][b]] - 2 * m->weight[a][b];
}

fn void enqueue_leaf(Matcher* m, usz v) {
    if (v == 0 || v > m->n || m->queued[v]) return;
    m->queue[m->tail] = v;
    m->tail = (m->tail + 1) % m->n;
    m->count++;
    m->queued[v] = true;
}

fn void enqueue_members(Matcher* m, usz x) {
    if (x <= m->n) { enqueue_leaf(m, x); return; }
    for (usz i = 0; i < (usz)m->member_count[x]; i++) enqueue_members(m, (usz)m->members[x][i]);
}

fn void set_top(Matcher* m, usz x, usz b) {
    m->top[x] = (short)b;
    if (x > m->n) for (usz i = 0; i < (usz)m->member_count[x]; i++) set_top(m, (usz)m->members[x][i], b);
}

fn void update_slack(Matcher* m, usz u, usz x) {
    usz old = (usz)m->slack_from[x];
    if (old == 0 || delta(m, u, x) < delta(m, old, x)) m->slack_from[x] = (short)u;
}

fn void refresh_slack(Matcher* m, usz x) {
    m->slack_from[x] = 0;
    for (usz u = 1; u <= m->n; u++) {
        usz representative = (usz)m->top[u];
        if (m->weight[u][x] > 0 && representative != x && m->state[representative] == 0) update_slack(m, u, x);
    }
}

fn usz cycle_position(Matcher* m, usz b, usz child) {
    usz size = (usz)m->member_count[b], pos = 0;
    while (pos < size && (usz)m->members[b][pos] != child) pos++;
    if (pos == size) return 0;
    if (pos % 2 == 1) {
        usz left = 1, right = size - 1;
        while (left < right) {
            short tmp = m->members[b][left]; m->members[b][left] = m->members[b][right]; m->members[b][right] = tmp;
            left++; right--;
        }
        pos = size - pos;
    }
    return pos;
}

fn void rotate_cycle(Matcher* m, usz b, usz start) {
    usz size = (usz)m->member_count[b];
    short[SLOTS] copy;
    for (usz i = 0; i < size; i++) copy[i] = m->members[b][(i + start) % size];
    for (usz i = 0; i < size; i++) m->members[b][i] = copy[i];
}

fn void set_pair(Matcher* m, usz u, usz v) {
    m->mate[u] = m->edge_b[u][v];
    if (u <= m->n) return;
    usz leaf = (usz)m->edge_a[u][v], entry = (usz)m->child_of[u][leaf];
    usz pos = cycle_position(m, u, entry);
    for (usz i = 0; i < pos; i++) set_pair(m, (usz)m->members[u][i], (usz)m->members[u][i ^ 1]);
    set_pair(m, entry, v);
    rotate_cycle(m, u, pos);
}

fn void augment(Matcher* m, usz u, usz v) {
    while (true) {
        usz next = (usz)m->top[(usz)m->mate[u]];
        set_pair(m, u, v);
        if (next == 0) return;
        usz prior = (usz)m->top[(usz)m->parent[next]];
        set_pair(m, next, prior);
        u = prior; v = next;
    }
}

fn usz common_base(Matcher* m, usz u, usz v) {
    m->epoch++;
    while (u != 0 || v != 0) {
        if (u != 0) {
            if (m->seen[u] == m->epoch) return u;
            m->seen[u] = m->epoch;
            u = (usz)m->top[(usz)m->mate[u]];
            if (u != 0) u = (usz)m->top[(usz)m->parent[u]];
        }
        usz tmp = u; u = v; v = tmp;
    }
    return 0;
}

fn void add_member(Matcher* m, usz b, usz x) {
    usz at = (usz)m->member_count[b];
    m->members[b][at] = (short)x;
    m->member_count[b]++;
}

fn void contract(Matcher* m, usz u, usz base, usz v) {
    usz b = m->n + 1;
    while (b <= m->nodes && m->top[b] != 0) b++;
    if (b > m->nodes) m->nodes++;
    m->dual[b] = 0; m->state[b] = 0; m->mate[b] = m->mate[base]; m->member_count[b] = 0;
    add_member(m, b, base);
    usz x = u;
    while (x != base) {
        add_member(m, b, x);
        usz y = (usz)m->top[(usz)m->mate[x]];
        add_member(m, b, y); enqueue_members(m, y);
        x = (usz)m->top[(usz)m->parent[y]];
    }
    usz end = (usz)m->member_count[b], left = 1, right = end - 1;
    while (left < right) {
        short tmp = m->members[b][left]; m->members[b][left] = m->members[b][right]; m->members[b][right] = tmp;
        left++; right--;
    }
    x = v;
    while (x != base) {
        add_member(m, b, x);
        usz y = (usz)m->top[(usz)m->mate[x]];
        add_member(m, b, y); enqueue_members(m, y);
        x = (usz)m->top[(usz)m->parent[y]];
    }
    set_top(m, b, b);
    for (usz y = 1; y <= m->nodes; y++) {
        m->weight[b][y] = 0; m->weight[y][b] = 0;
        m->edge_a[b][y] = 0; m->edge_b[b][y] = 0;
        m->edge_a[y][b] = 0; m->edge_b[y][b] = 0;
    }
    for (usz leaf = 0; leaf <= MAX_N; leaf++) m->child_of[b][leaf] = 0;
    for (usz i = 0; i < (usz)m->member_count[b]; i++) {
        usz child = (usz)m->members[b][i];
        for (usz y = 1; y <= m->nodes; y++) {
            if (m->weight[child][y] == 0) continue;
            if (m->weight[b][y] == 0 || delta(m, child, y) < delta(m, b, y)) {
                m->weight[b][y] = m->weight[child][y];
                m->edge_a[b][y] = m->edge_a[child][y]; m->edge_b[b][y] = m->edge_b[child][y];
                m->weight[y][b] = m->weight[y][child];
                m->edge_a[y][b] = m->edge_a[y][child]; m->edge_b[y][b] = m->edge_b[y][child];
            }
        }
        for (usz leaf = 1; leaf <= m->n; leaf++) {
            bool contains = child <= m->n ? child == leaf : m->child_of[child][leaf] != 0;
            if (contains) m->child_of[b][leaf] = (short)child;
        }
    }
    refresh_slack(m, b);
}

fn void expand_blossom(Matcher* m, usz b) {
    for (usz i = 0; i < (usz)m->member_count[b]; i++) {
        usz child = (usz)m->members[b][i]; set_top(m, child, child);
    }
    usz outside = (usz)m->parent[b];
    usz entry_leaf = (usz)m->edge_a[b][outside];
    usz entry = (usz)m->child_of[b][entry_leaf];
    usz pos = cycle_position(m, b, entry);
    for (usz i = 0; i < pos; i += 2) {
        usz inner = (usz)m->members[b][i], outer = (usz)m->members[b][i + 1];
        m->parent[inner] = m->edge_a[outer][inner];
        m->state[inner] = 1; m->state[outer] = 0; m->slack_from[inner] = 0;
        refresh_slack(m, outer); enqueue_members(m, outer);
    }
    m->state[entry] = 1; m->parent[entry] = (short)outside;
    for (usz i = pos + 1; i < (usz)m->member_count[b]; i++) {
        usz child = (usz)m->members[b][i]; m->state[child] = -1; refresh_slack(m, child);
    }
    m->top[b] = 0;
}

fn bool process_edge(Matcher* m, usz left, usz right) {
    usz u = (usz)m->top[left], v = (usz)m->top[right];
    if (m->state[v] == -1) {
        m->parent[v] = (short)left; m->state[v] = 1;
        usz next = (usz)m->top[(usz)m->mate[v]];
        m->slack_from[v] = 0; m->slack_from[next] = 0; m->state[next] = 0; enqueue_members(m, next);
    } else if (m->state[v] == 0) {
        usz base = common_base(m, u, v);
        if (base == 0) { augment(m, u, v); augment(m, v, u); return true; }
        contract(m, u, base, v);
    }
    return false;
}

fn bool stage(Matcher* m) {
    for (usz x = 0; x <= m->nodes; x++) { m->state[x] = -1; m->slack_from[x] = 0; }
    m->head = 0; m->tail = 0; m->count = 0;
    for (usz x = 0; x <= MAX_N; x++) m->queued[x] = false;
    for (usz x = 1; x <= m->nodes; x++) {
        if ((usz)m->top[x] == x && m->mate[x] == 0) {
            m->parent[x] = 0; m->state[x] = 0; enqueue_members(m, x);
        }
    }
    if (m->count == 0) return false;
    while (true) {
        while (m->count != 0) {
            usz u = m->queue[m->head]; m->head = (m->head + 1) % m->n; m->count--; m->queued[u] = false;
            if (m->state[(usz)m->top[u]] == 1) continue;
            for (usz v = 1; v <= m->n; v++) {
                if (m->weight[u][v] == 0 || m->top[u] == m->top[v]) continue;
                if (delta(m, u, v) == 0) {
                    if (process_edge(m, (usz)m->edge_a[u][v], (usz)m->edge_b[u][v])) return true;
                } else update_slack(m, u, (usz)m->top[v]);
            }
        }
        long step = INF;
        for (usz u = 1; u <= m->n; u++) if (m->state[(usz)m->top[u]] == 0 && m->dual[u] < step) step = m->dual[u];
        for (usz b = m->n + 1; b <= m->nodes; b++)
            if ((usz)m->top[b] == b && m->state[b] == 1 && m->dual[b] / 2 < step) step = m->dual[b] / 2;
        for (usz x = 1; x <= m->nodes; x++) {
            if ((usz)m->top[x] != x || m->slack_from[x] == 0) continue;
            long slack = delta(m, (usz)m->slack_from[x], x);
            if (m->state[x] == -1 && slack < step) step = slack;
            else if (m->state[x] == 0 && slack / 2 < step) step = slack / 2;
        }
        if (step == INF) return false;
        for (usz u = 1; u <= m->n; u++) {
            short state = m->state[(usz)m->top[u]];
            if (state == 0) { if (m->dual[u] == step) return false; m->dual[u] -= step; }
            else if (state == 1) m->dual[u] += step;
        }
        for (usz b = m->n + 1; b <= m->nodes; b++) {
            if ((usz)m->top[b] != b) continue;
            if (m->state[b] == 0) m->dual[b] += 2 * step;
            else if (m->state[b] == 1) m->dual[b] -= 2 * step;
        }
        for (usz x = 1; x <= m->nodes; x++) {
            if ((usz)m->top[x] == x && m->slack_from[x] != 0 && (usz)m->top[(usz)m->slack_from[x]] != x &&
                delta(m, (usz)m->slack_from[x], x) == 0) {
                usz source = (usz)m->slack_from[x];
                if (process_edge(m, (usz)m->edge_a[source][x], (usz)m->edge_b[source][x])) return true;
            }
        }
        for (usz b = m->n + 1; b <= m->nodes; b++)
            if ((usz)m->top[b] == b && m->state[b] == 1 && m->dual[b] == 0) expand_blossom(m, b);
    }
}

fn long general_weighted_matching_primal_dual_blossom(long* input, usz length) @export("general_weighted_matching_primal_dual_blossom") {
    if (input == null || length < 2 || length > 6051) return -2;
    long nval = input[0], mval = input[1];
    if (nval < 1 || nval > 64 || mval < 0 || mval > nval * (nval - 1) / 2) return -2;
    usz n = (usz)nval, edges = (usz)mval;
    if (length != 2 + 3 * edges) return -2;
    Matcher m = {}; m.n = n; m.nodes = n;
    long largest = 0;
    for (usz i = 0; i < edges; i++) {
        long uval = input[2 + 3 * i], vval = input[3 + 3 * i], wt = input[4 + 3 * i];
        if (uval < 0 || uval >= nval || vval < 0 || vval >= nval || uval == vval || wt < 1 || wt > 1000000) return -2;
        usz u = (usz)uval + 1, v = (usz)vval + 1;
        if (m.weight[u][v] != 0) return -2;
        m.weight[u][v] = wt; m.weight[v][u] = wt;
        m.edge_a[u][v] = (short)u; m.edge_b[u][v] = (short)v;
        m.edge_a[v][u] = (short)v; m.edge_b[v][u] = (short)u;
        if (wt > largest) largest = wt;
    }
    for (usz u = 1; u <= n; u++) { m.top[u] = (short)u; m.dual[u] = largest; m.child_of[u][u] = (short)u; }
    while (stage(&m)) { }
    long answer = 0;
    for (usz u = 1; u <= n; u++) if ((usz)m.mate[u] > u) answer += m.weight[u][(usz)m.mate[u]];
    return answer;
}
