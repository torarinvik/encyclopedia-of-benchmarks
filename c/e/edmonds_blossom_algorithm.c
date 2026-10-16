/* Edmonds blossom contraction for maximum matching in a small general graph. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 20
#define MAX_EDGES (MAX_VERTICES * (MAX_VERTICES - 1) / 2)

static bool graph[MAX_VERTICES][MAX_VERTICES];
static int match[MAX_VERTICES], parent[MAX_VERTICES], base[MAX_VERTICES];
static bool used[MAX_VERTICES], blossom[MAX_VERTICES];
static int queue[MAX_VERTICES];

static int lca(int a, int b)
{
    bool path[MAX_VERTICES] = {false};
    while (true) {
        a = base[a];
        path[a] = true;
        if (match[a] == -1) break;
        a = parent[match[a]];
    }
    while (true) {
        b = base[b];
        if (path[b]) return b;
        b = parent[match[b]];
    }
}

static void mark_path(int v, int b, int child)
{
    while (base[v] != b) {
        blossom[base[v]] = true;
        blossom[base[match[v]]] = true;
        parent[v] = child;
        child = match[v];
        v = parent[match[v]];
    }
}

static int find_path(int root, int n)
{
    for (int i = 0; i < n; ++i) {
        used[i] = false;
        parent[i] = -1;
        base[i] = i;
    }
    int head = 0, tail = 0;
    queue[tail++] = root;
    used[root] = true;
    while (head < tail) {
        const int v = queue[head++];
        for (int u = 0; u < n; ++u) {
            if (!graph[v][u] || base[v] == base[u] || match[v] == u) continue;
            if (u == root || (match[u] != -1 && parent[match[u]] != -1)) {
                const int cur = lca(v, u);
                for (int i = 0; i < n; ++i) blossom[i] = false;
                mark_path(v, cur, u);
                mark_path(u, cur, v);
                for (int i = 0; i < n; ++i) {
                    if (!blossom[base[i]]) continue;
                    base[i] = cur;
                    if (!used[i]) {
                        used[i] = true;
                        queue[tail++] = i;
                    }
                }
            } else if (parent[u] == -1) {
                parent[u] = v;
                if (match[u] == -1) return u;
                const int next = match[u];
                used[next] = true;
                queue[tail++] = next;
            }
        }
    }
    return -1;
}

int64_t edmonds_blossom_algorithm(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const int n = (int)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;
    for (int i = 0; i < MAX_VERTICES; ++i) {
        match[i] = -1;
        for (int j = 0; j < MAX_VERTICES; ++j) graph[i][j] = false;
    }
    for (size_t i = 0; i < m; ++i) {
        const int64_t a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || a >= n || b < 0 || b >= n || a == b) return -1;
        graph[a][b] = graph[b][a] = true;
    }
    int answer = 0;
    for (int i = 0; i < n; ++i) {
        if (match[i] != -1) continue;
        int v = find_path(i, n);
        while (v != -1) {
            const int pv = parent[v];
            const int next = match[pv];
            match[v] = pv;
            match[pv] = v;
            v = next;
        }
        if (match[i] != -1) ++answer;
    }
    return answer;
}
