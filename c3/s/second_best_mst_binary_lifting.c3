module second_best_mst_binary_lifting;

struct TopPair { long first; long second; }

fn TopPair merge(TopPair a, TopPair b) {
    TopPair result = { -1, -1 };
    long[4] values = { a.first, a.second, b.first, b.second };
    for (int i = 0; i < 4; i++) {
        long value = values[i];
        if (value > result.first) {
            result.second = result.first;
            result.first = value;
        } else if (value < result.first && value > result.second) {
            result.second = value;
        }
    }
    return result;
}

fn int root(int* parent, int initial) {
    int vertex = initial;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

fn long second_best_mst_binary_lifting(long* input, usz length) @export("second_best_mst_binary_lifting") {
    if (input == null || length < 2 || length > 63) return -1;
    long nv = input[0], mv = input[1];
    if (nv < 1 || nv > 8 || mv < nv - 1 || mv > 20 || length != (usz)(2 + 3 * mv)) return -1;
    int n = (int)nv, m = (int)mv;
    int[20] u = zeroed, v = zeroed, order = zeroed;
    long[20] weight = zeroed;
    bool[64] seen = zeroed;
    for (int i = 0; i < m; i++) {
        long a = input[2 + 3 * i], b = input[3 + 3 * i], w = input[4 + 3 * i];
        if (a < 0 || a >= b || b >= nv || w < 0 || w > 1000000) return -1;
        int pos = (int)(a * 8 + b);
        if (seen[pos]) return -1;
        seen[pos] = true;
        u[i] = (int)a; v[i] = (int)b; weight[i] = w; order[i] = i;
    }
    for (int i = 1; i < m; i++) {
        int edge = order[i], j = i;
        while (j > 0 && weight[order[j - 1]] > weight[edge]) {
            order[j] = order[j - 1]; j--;
        }
        order[j] = edge;
    }
    int[8] parent = zeroed, degree = zeroed;
    int[64] adjacent = zeroed, edge_at = zeroed;
    bool[20] selected = zeroed;
    for (int i = 0; i < n; i++) parent[i] = i;
    int count = 0;
    long total = 0;
    for (int i = 0; i < m; i++) {
        int edge = order[i];
        int a = root(&parent[0], u[edge]), b = root(&parent[0], v[edge]);
        if (a == b) continue;
        parent[a] = b; selected[edge] = true; count++; total += weight[edge];
        int pu = u[edge] * 8 + degree[u[edge]]++;
        int pv = v[edge] * 8 + degree[v[edge]]++;
        adjacent[pu] = v[edge]; edge_at[pu] = edge;
        adjacent[pv] = u[edge]; edge_at[pv] = edge;
    }
    if (count != n - 1) return -1;
    int[32] up = zeroed;
    TopPair[32] best = zeroed;
    int[8] depth = zeroed, queue = zeroed;
    for (int i = 0; i < 32; i++) best[i] = { -1, -1 };
    for (int i = 0; i < n; i++) depth[i] = -1;
    depth[0] = 0; queue[0] = 0;
    int head = 0, tail = 1;
    while (head < tail) {
        int vertex = queue[head++];
        for (int i = 0; i < degree[vertex]; i++) {
            int pos = vertex * 8 + i, next = adjacent[pos];
            if (depth[next] >= 0) continue;
            depth[next] = depth[vertex] + 1; up[next] = vertex;
            best[next] = { weight[edge_at[pos]], -1 };
            queue[tail++] = next;
        }
    }
    for (int level = 1; level < 4; level++) {
        for (int vertex = 0; vertex < n; vertex++) {
            int prev = (level - 1) * 8 + vertex;
            int other = (level - 1) * 8 + up[prev], dest = level * 8 + vertex;
            up[dest] = up[other];
            best[dest] = merge(best[prev], best[other]);
        }
    }
    long increase = -1;
    for (int edge = 0; edge < m; edge++) {
        if (selected[edge]) continue;
        int a = u[edge], b = v[edge];
        if (depth[a] < depth[b]) { int tmp = a; a = b; b = tmp; }
        TopPair path = { -1, -1 };
        int difference = depth[a] - depth[b];
        for (int level = 0; level < 4; level++) {
            if ((difference & (1 << level)) != 0) {
                int pos = level * 8 + a;
                path = merge(path, best[pos]); a = up[pos];
            }
        }
        if (a != b) {
            for (int level = 3; level >= 0; level--) {
                int pa = level * 8 + a, pb = level * 8 + b;
                if (up[pa] != up[pb]) {
                    path = merge(merge(path, best[pa]), best[pb]);
                    a = up[pa]; b = up[pb];
                }
            }
            path = merge(merge(path, best[a]), best[b]);
        }
        long removed = weight[edge] > path.first ? path.first : path.second;
        if (removed >= 0 && removed < weight[edge]) {
            long delta = weight[edge] - removed;
            if (increase < 0 || delta < increase) increase = delta;
        }
    }
    return increase < 0 ? 0 : total + increase + 1;
}
