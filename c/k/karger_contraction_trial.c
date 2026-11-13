#include <stddef.h>
#include <stdint.h>

static int root(int parent[8], int vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}

int64_t karger_contraction_trial(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 57) return -1;
    if (input[0] < 2 || input[0] > 8 || input[1] < 1 || input[1] > 24) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != (size_t)(2 + 2 * m + n - 2)) return -1;
    int u[24], v[24], parent[8];
    for (int i = 0; i < n; ++i) parent[i] = i;
    for (int i = 0; i < m; ++i) {
        int64_t a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= n || b >= n || a == b) return -1;
        u[i] = (int)a; v[i] = (int)b;
        int left = root(parent, u[i]), right = root(parent, v[i]);
        parent[left] = right;
    }
    int initial = root(parent, 0);
    for (int i = 1; i < n; ++i) if (root(parent, i) != initial) return -1;
    for (int i = 0; i < n; ++i) parent[i] = i;
    for (int step = 0; step < n - 2; ++step) {
        int live = 0;
        for (int i = 0; i < m; ++i) if (root(parent, u[i]) != root(parent, v[i])) ++live;
        int64_t rank = input[2 + 2 * m + step];
        if (rank < 0 || rank >= live) return -1;
        for (int i = 0; i < m; ++i) {
            int left = root(parent, u[i]), right = root(parent, v[i]);
            if (left == right) continue;
            if (rank == 0) { parent[left] = right; break; }
            --rank;
        }
    }
    int cut = 0;
    for (int i = 0; i < m; ++i) if (root(parent, u[i]) != root(parent, v[i])) ++cut;
    return cut;
}
