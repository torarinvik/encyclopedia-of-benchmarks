#include <stddef.h>
#include <stdint.h>

#define MBSTF_MAX_N 6
#define MBSTF_MAX_M 8
#define MBSTF_MAX_INPUT 37
#define MBSTF_NODE_CAP 8
#define MBSTF_MATRIX_CAP (MBSTF_NODE_CAP * MBSTF_NODE_CAP)

static int mbstf_feasible(const int64_t *input, size_t n, size_t m,
                          size_t source, size_t sink, int64_t flow_cap) {
    int64_t residual[MBSTF_MATRIX_CAP] = {0};
    int64_t balance[MBSTF_MAX_N] = {0};
    for (size_t i = 0; i < m; ++i) {
        const size_t offset = 4 + 4 * i;
        const size_t u = (size_t)input[offset];
        const size_t v = (size_t)input[offset + 1];
        const int64_t lower = input[offset + 2];
        const int64_t upper = input[offset + 3];
        residual[u * MBSTF_NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }
    residual[sink * MBSTF_NODE_CAP + source] += flow_cap;

    const size_t super_source = n;
    const size_t super_sink = n + 1;
    const size_t node_count = n + 2;
    int64_t demand = 0;
    for (size_t v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            residual[super_source * MBSTF_NODE_CAP + v] += balance[v];
            demand += balance[v];
        } else if (balance[v] < 0) {
            residual[v * MBSTF_NODE_CAP + super_sink] += -balance[v];
        }
    }

    int64_t flow = 0;
    while (flow < demand) {
        int parent[MBSTF_NODE_CAP];
        for (size_t v = 0; v < node_count; ++v) parent[v] = -1;
        size_t queue[MBSTF_NODE_CAP];
        size_t head = 0, tail = 0;
        parent[super_source] = (int)super_source;
        queue[tail++] = super_source;
        while (head < tail && parent[super_sink] < 0) {
            const size_t u = queue[head++];
            for (size_t v = 0; v < node_count; ++v) {
                if (residual[u * MBSTF_NODE_CAP + v] > 0 && parent[v] < 0) {
                    parent[v] = (int)u;
                    queue[tail++] = v;
                    if (v == super_sink) break;
                }
            }
        }
        if (parent[super_sink] < 0) break;
        int64_t amount = demand - flow;
        for (size_t v = super_sink; v != super_source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            if (residual[u * MBSTF_NODE_CAP + v] < amount)
                amount = residual[u * MBSTF_NODE_CAP + v];
        }
        for (size_t v = super_sink; v != super_source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            residual[u * MBSTF_NODE_CAP + v] -= amount;
            residual[v * MBSTF_NODE_CAP + u] += amount;
        }
        flow += amount;
    }
    return flow == demand;
}

int64_t minimum_bounded_s_t_flow(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MBSTF_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    const int64_t source_value = input[2];
    const int64_t sink_value = input[3];
    if (n_value < 2 || n_value > MBSTF_MAX_N || m_value < 0 || m_value > MBSTF_MAX_M)
        return -1;
    if (source_value < 0 || source_value >= n_value || sink_value < 0 ||
        sink_value >= n_value || source_value == sink_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    const size_t source = (size_t)source_value;
    const size_t sink = (size_t)sink_value;
    if (length != 4 + 4 * m) return -1;

    int64_t upper_bound = 0;
    for (size_t i = 0; i < m; ++i) {
        const size_t offset = 4 + 4 * i;
        const int64_t u = input[offset];
        const int64_t v = input[offset + 1];
        const int64_t lower = input[offset + 2];
        const int64_t upper = input[offset + 3];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || lower < 0 ||
            upper < lower || upper > 2) return -1;
        if ((size_t)u == source && (size_t)v != source) upper_bound += upper;
    }

    int64_t low = 0;
    int64_t high = upper_bound + 1;
    while (low < high) {
        const int64_t middle = low + (high - low) / 2;
        if (mbstf_feasible(input, n, m, source, sink, middle)) high = middle;
        else low = middle + 1;
    }
    return low > upper_bound ? -2 : low;
}
