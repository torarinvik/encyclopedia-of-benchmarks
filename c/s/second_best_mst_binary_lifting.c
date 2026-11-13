#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t first, second; } maxima;

static maxima merge(maxima a, maxima b) {
    int64_t values[4] = {a.first, a.second, b.first, b.second};
    maxima result = {-1, -1};
    for (int i = 0; i < 4; ++i) {
        int64_t value = values[i];
        if (value > result.first) {
            result.second = result.first;
            result.first = value;
        } else if (value < result.first && value > result.second) {
            result.second = value;
        }
    }
    return result;
}

static int find_root(int parent[8], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

int64_t second_best_mst_binary_lifting(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 63) return -1;
    int64_t nv = input[0], mv = input[1];
    if (nv < 1 || nv > 8 || mv < nv - 1 || mv > 20 || length != (size_t)(2 + 3 * mv)) return -1;
    int n = (int)nv, m = (int)mv;
    int u[20], v[20], order[20], selected[20] = {0}, seen[8][8] = {{0}};
    int64_t weight[20];
    for (int i = 0; i < m; ++i) {
        int64_t a = input[2 + 3 * i], b = input[3 + 3 * i], w = input[4 + 3 * i];
        if (a < 0 || a >= b || b >= nv || w < 0 || w > 1000000 || seen[a][b]) return -1;
        seen[a][b] = 1; u[i] = (int)a; v[i] = (int)b; weight[i] = w; order[i] = i;
    }
    for (int i = 1; i < m; ++i) {
        int edge = order[i], j = i;
        while (j > 0 && weight[order[j - 1]] > weight[edge]) { order[j] = order[j - 1]; --j; }
        order[j] = edge;
    }
    int parent[8], degree[8] = {0}, adjacent[8][8], edge_at[8][8], count = 0;
    int64_t total = 0;
    for (int i = 0; i < n; ++i) parent[i] = i;
    for (int i = 0; i < m; ++i) {
        int e = order[i], a = find_root(parent, u[e]), b = find_root(parent, v[e]);
        if (a == b) continue;
        parent[a] = b; selected[e] = 1; ++count; total += weight[e];
        adjacent[u[e]][degree[u[e]]] = v[e]; edge_at[u[e]][degree[u[e]]++] = e;
        adjacent[v[e]][degree[v[e]]] = u[e]; edge_at[v[e]][degree[v[e]]++] = e;
    }
    if (count != n - 1) return -1;
    int up[4][8] = {{0}}, depth[8], queue[8], head = 0, tail = 0;
    maxima table[4][8];
    for (int level = 0; level < 4; ++level)
        for (int i = 0; i < n; ++i) table[level][i] = (maxima){-1, -1};
    for (int i = 0; i < n; ++i) depth[i] = -1;
    depth[0] = 0; queue[tail++] = 0;
    while (head < tail) {
        int vertex = queue[head++];
        for (int i = 0; i < degree[vertex]; ++i) {
            int next = adjacent[vertex][i];
            if (depth[next] >= 0) continue;
            depth[next] = depth[vertex] + 1; up[0][next] = vertex;
            table[0][next] = (maxima){weight[edge_at[vertex][i]], -1};
            queue[tail++] = next;
        }
    }
    for (int level = 1; level < 4; ++level)
        for (int i = 0; i < n; ++i) {
            int mid = up[level - 1][i];
            up[level][i] = up[level - 1][mid];
            table[level][i] = merge(table[level - 1][i], table[level - 1][mid]);
        }
    int64_t increase = -1;
    for (int edge = 0; edge < m; ++edge) {
        if (selected[edge]) continue;
        int a = u[edge], b = v[edge];
        maxima path = {-1, -1};
        if (depth[a] < depth[b]) { int t = a; a = b; b = t; }
        int difference = depth[a] - depth[b];
        for (int level = 0; level < 4; ++level)
            if (difference & (1 << level)) { path = merge(path, table[level][a]); a = up[level][a]; }
        if (a != b) {
            for (int level = 3; level >= 0; --level)
                if (up[level][a] != up[level][b]) {
                    path = merge(merge(path, table[level][a]), table[level][b]);
                    a = up[level][a]; b = up[level][b];
                }
            path = merge(merge(path, table[0][a]), table[0][b]);
        }
        int64_t removed = weight[edge] > path.first ? path.first : path.second;
        if (removed >= 0 && removed < weight[edge]) {
            int64_t delta = weight[edge] - removed;
            if (increase < 0 || delta < increase) increase = delta;
        }
    }
    return increase < 0 ? 0 : total + increase + 1;
}
