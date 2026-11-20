/* Clean-room McCreight radix priority-search-tree profile. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { PST_N = 8, PST_Q = 7, PST_X = 32, PST_MAX_INPUT = 47, PST_PARSEABLE = 48 };

int64_t priority_search_tree_three_sided_reporting(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > PST_PARSEABLE) return -1;
    const int64_t n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > PST_N || q64 < 0 || q64 > PST_Q ||
        length != 2 + 3 * (size_t)n64 + 3 * (size_t)q64) return -1;
    const int n = (int)n64, q = (int)q64;
    int node_x[PST_N], node_y[PST_N], node_label[PST_N];
    int left[PST_N], right[PST_N], node_low[PST_N], node_high[PST_N];
    bool seen_x[PST_X] = {false}, seen_label[PST_N] = {false};
    for (int i = 0; i < PST_N; ++i) left[i] = right[i] = -1;
    int root = -1, node_count = 0;
    size_t at = 2;
    for (int record = 0; record < n; ++record) {
        const int64_t x64 = input[at++], y64 = input[at++], label64 = input[at++];
        if (x64 < 0 || x64 >= PST_X || y64 < -64 || y64 > 63 ||
            label64 < 0 || label64 >= PST_N || seen_x[x64] || seen_label[label64]) return -1;
        seen_x[x64] = true; seen_label[label64] = true;
        int px = (int)x64, py = (int)y64, plabel = (int)label64;
        if (root < 0) {
            root = node_count++;
            node_x[root] = px; node_y[root] = py; node_label[root] = plabel;
            node_low[root] = 0; node_high[root] = PST_X;
            continue;
        }
        int current = root, low = 0, high = PST_X;
        for (;;) {
            if (py < node_y[current]) {
                int temp = node_x[current]; node_x[current] = px; px = temp;
                temp = node_y[current]; node_y[current] = py; py = temp;
                temp = node_label[current]; node_label[current] = plabel; plabel = temp;
            }
            const int middle = (low + high) / 2;
            if (px < middle) {
                if (left[current] < 0) {
                    const int child = node_count++;
                    left[current] = child; node_x[child] = px; node_y[child] = py;
                    node_label[child] = plabel; left[child] = right[child] = -1;
                    node_low[child] = low; node_high[child] = middle; break;
                }
                current = left[current]; high = middle;
            } else {
                if (right[current] < 0) {
                    const int child = node_count++;
                    right[current] = child; node_x[child] = px; node_y[child] = py;
                    node_label[child] = plabel; left[child] = right[child] = -1;
                    node_low[child] = middle; node_high[child] = high; break;
                }
                current = right[current]; low = middle;
            }
        }
    }
    int query_x0[PST_Q], query_x1[PST_Q], query_y1[PST_Q];
    for (int i = 0; i < q; ++i) {
        const int64_t x0 = input[at++], x1 = input[at++], y1 = input[at++];
        if (x0 < 0 || x0 > x1 || x1 >= PST_X || y1 < -64 || y1 > 63) return -1;
        query_x0[i] = (int)x0; query_x1[i] = (int)x1; query_y1[i] = (int)y1;
    }
    int64_t result = 0;
    for (int query = 0; query < q; ++query) {
        uint16_t mask = 0;
        if (root >= 0) {
            int stack[PST_N], top = 0;
            stack[top++] = root;
            while (top > 0) {
                const int node = stack[--top];
                if (query_x1[query] < node_low[node] || query_x0[query] >= node_high[node] ||
                    node_y[node] > query_y1[query]) continue;
                if (query_x0[query] <= node_x[node] && node_x[node] <= query_x1[query])
                    mask |= (uint16_t)(1u << node_label[node]);
                if (left[node] >= 0) stack[top++] = left[node];
                if (right[node] >= 0) stack[top++] = right[node];
            }
        }
        result |= (int64_t)mask << (8 * query);
    }
    return result;
}
