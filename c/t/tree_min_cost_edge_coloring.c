/* Uncompiled matching-sensitivity tree edge-coloring draft. */
#include <stddef.h>
#include <stdint.h>

#define TEC_INF INT64_C(1000000000000000)

/* d rows, width d or d+1; one optimum matching, then all column deletions. */
static int tec_assignment(int d, int width, int64_t cost[16][16],
                          int64_t *base, int64_t deletion[16]) {
    int64_t row_dual[17] = {0}, col_dual[17] = {0};
    int owner[17] = {0};
    for (int row = 1; row <= d; ++row) {
        int previous[17] = {0}, used[17] = {0};
        int64_t slack[17];
        for (int col = 0; col <= width; ++col) slack[col] = TEC_INF;
        owner[0] = row;
        int col = 0;
        for (;;) {
            used[col] = 1;
            int active_row = owner[col], next_col = 0;
            int64_t step = TEC_INF;
            for (int candidate = 1; candidate <= width; ++candidate) {
                if (used[candidate]) continue;
                int64_t reduced = cost[active_row-1][candidate-1]
                                  - row_dual[active_row] - col_dual[candidate];
                if (reduced < slack[candidate]) {
                    slack[candidate] = reduced;
                    previous[candidate] = col;
                }
                if (slack[candidate] < step) { step = slack[candidate]; next_col = candidate; }
            }
            if (!next_col) return 0;
            for (int candidate = 0; candidate <= width; ++candidate) {
                if (used[candidate]) { row_dual[owner[candidate]] += step; col_dual[candidate] -= step; }
                else if (candidate) slack[candidate] -= step;
            }
            col = next_col;
            if (!owner[col]) break;
        }
        while (col) {
            int parent = previous[col];
            owner[col] = owner[parent];
            col = parent;
        }
    }
    *base = 0;
    int free_col = -1;
    for (int col = 0; col < width; ++col) {
        if (owner[col+1]) *base += cost[owner[col+1]-1][col];
        else free_col = col;
    }
    if (width == d) return 1;
    if (free_col < 0) return 0;
    int64_t distance[16], updated[16];
    for (int col = 0; col < width; ++col) distance[col] = col == free_col ? 0 : TEC_INF;
    for (int pass = 0; pass < d; ++pass) {
        for (int col = 0; col < width; ++col) updated[col] = distance[col];
        for (int col = 0; col < width; ++col) {
            int row = owner[col+1]-1;
            if (row < 0) continue;
            for (int dest = 0; dest < width; ++dest) if (distance[dest] != TEC_INF) {
                int64_t candidate = cost[row][dest]-cost[row][col]+distance[dest];
                if (candidate < updated[col]) updated[col] = candidate;
            }
        }
        for (int col = 0; col < width; ++col) distance[col] = updated[col];
    }
    for (int col = 0; col < width; ++col) {
        if (distance[col] == TEC_INF) return 0;
        deletion[col] = *base + distance[col];
    }
    return 1;
}

int64_t tree_min_cost_edge_coloring(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 82) return -1;
    int64_t nv = input[0], kv = input[1];
    if (nv < 1 || nv > 64 || kv < 1 || kv > 16) return -1;
    int n = (int)nv, k = (int)kv;
    if (length != (size_t)(n+1+k)) return -1;
    int parents[64] = {0}, degree[64] = {0}, child_count[64] = {0};
    for (int vertex = 1; vertex < n; ++vertex) {
        int64_t parent = input[1+vertex];
        if (parent < 0 || parent >= vertex) return -1;
        parents[vertex] = (int)parent;
        ++degree[parent]; ++degree[vertex];
    }
    int64_t prices[16];
    for (int c = 0; c < k; ++c) {
        int64_t value = input[n+1+c];
        if (value < 0 || value > 1000000) return -1;
        prices[c] = value;
    }
    for (int v = 0; v < n; ++v) if (degree[v] > k) return -2;
    for (int c = 1; c < k; ++c) {
        int64_t value = prices[c]; int j = c;
        while (j > 0 && prices[j-1] > value) { prices[j] = prices[j-1]; --j; }
        prices[j] = value;
    }
    int children[64][16];
    for (int v = 1; v < n; ++v) children[parents[v]][child_count[parents[v]]++] = v;
    int64_t tables[64][16] = {{0}};
    for (int vertex = n-1; vertex >= 0; --vertex) {
        int d = child_count[vertex];
        if (!d) continue;
        int saturated_root = vertex == 0 && d == k;
        int width = saturated_root ? d : d+1;
        int64_t cost[16][16], deletion[16], base;
        for (int row = 0; row < d; ++row) {
            int child = children[vertex][row], last = child_count[child];
            for (int col = 0; col < width; ++col) {
                int index = col < last ? col : last;
                cost[row][col] = prices[col] + tables[child][index];
            }
        }
        if (!tec_assignment(d, width, cost, &base, deletion)) return -1;
        if (saturated_root) tables[vertex][0] = base;
        else for (int col = 0; col < width; ++col) tables[vertex][col] = deletion[col];
    }
    return child_count[0] == k ? tables[0][0] : tables[0][child_count[0]];
}
