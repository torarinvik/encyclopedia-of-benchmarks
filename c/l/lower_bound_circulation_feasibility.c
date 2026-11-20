#include <stddef.h>
#include <stdint.h>

#define LBCF_MAX_N 6
#define LBCF_MAX_M 8
#define LBCF_MAX_INPUT 35
#define LBCF_NODE_CAP 8
#define LBCF_MATRIX_CAP (LBCF_NODE_CAP * LBCF_NODE_CAP)

int64_t lower_bound_circulation_feasibility(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > LBCF_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > LBCF_MAX_N || m_value < 0 || m_value > LBCF_MAX_M) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + 4 * m) return -1;

    int64_t residual[LBCF_MATRIX_CAP] = {0};
    int64_t balance[LBCF_MAX_N] = {0};
    for (size_t i = 0; i < m; ++i) {
        const size_t offset = 2 + 4 * i;
        const int64_t u_value = input[offset];
        const int64_t v_value = input[offset + 1];
        const int64_t lower = input[offset + 2];
        const int64_t upper = input[offset + 3];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            lower < 0 || upper < lower || upper > 2) return -1;
        const size_t u = (size_t)u_value;
        const size_t v = (size_t)v_value;
        residual[u * LBCF_NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }

    const size_t source = n;
    const size_t sink = n + 1;
    const size_t node_count = n + 2;
    int64_t demand = 0;
    for (size_t v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            residual[source * LBCF_NODE_CAP + v] += balance[v];
            demand += balance[v];
        } else if (balance[v] < 0) {
            residual[v * LBCF_NODE_CAP + sink] += -balance[v];
        }
    }

    int64_t flow = 0;
    while (flow < demand) {
        int parent[LBCF_NODE_CAP];
        for (size_t v = 0; v < node_count; ++v) parent[v] = -1;
        size_t queue[LBCF_NODE_CAP];
        size_t head = 0, tail = 0;
        parent[source] = (int)source;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const size_t u = queue[head++];
            for (size_t v = 0; v < node_count; ++v) {
                if (residual[u * LBCF_NODE_CAP + v] > 0 && parent[v] < 0) {
                    parent[v] = (int)u;
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        int64_t amount = demand - flow;
        for (size_t v = sink; v != source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            if (residual[u * LBCF_NODE_CAP + v] < amount)
                amount = residual[u * LBCF_NODE_CAP + v];
        }
        for (size_t v = sink; v != source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            residual[u * LBCF_NODE_CAP + v] -= amount;
            residual[v * LBCF_NODE_CAP + u] += amount;
        }
        flow += amount;
    }
    return flow == demand ? 1 : 0;
}
