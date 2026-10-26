/* Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_E = 28, MAX_INPUT = 5 + MAX_N + 3 * MAX_E,
       MAX_ROUNDS = 256 };
static const int64_t INF_VALUE = INT64_C(1000000000);

static void enqueue_once(int vertex, int *queue, int *count, uint8_t *seen) {
    if (!seen[vertex]) {
        seen[vertex] = 1;
        queue[(*count)++] = vertex;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

extern "C" int64_t saga_incremental_analytics(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t mode64 = input[0], n64 = input[1], base64 = input[2];
    const int64_t added64 = input[3], source64 = input[4];
    if (mode64 < 1 || mode64 > 6 || n64 < 2 || n64 > MAX_N ||
        base64 < 0 || added64 < 1 || base64 + added64 > MAX_E ||
        length != 5 + (size_t)n64 + 3 * (size_t)(base64 + added64)) return -1;
    const int mode = (int)mode64, n = (int)n64;
    const int base_edges = (int)base64, added_edges = (int)added64;
    const int edge_count = base_edges + added_edges;
    if ((mode == 1 || mode == 2 || mode == 5) ?
        (source64 < 0 || source64 >= n64) : (source64 != -1)) return -1;

    int64_t property[MAX_N];
    const size_t edge_offset = 5 + (size_t)n;
    for (int v = 0; v < n; ++v) {
        const int64_t value = input[5 + (size_t)v];
        if (mode == 1) {
            if (value < -1 || value >= n64) return -1;
        } else if (mode == 2 || mode == 5) {
            if (value < -1 || value > INF_VALUE) return -1;
        } else if (mode == 3) {
            if (value < -1 || value > INT64_C(1000000)) return -1;
        } else if (value < -1 || value >= n64) {
            return -1;
        }
        property[v] = value;
    }

    int neighbor[MAX_N][MAX_N], weight[MAX_N][MAX_N], degree[MAX_N] = {0};
    uint8_t edge_seen[MAX_N][MAX_N] = {{0}}, affected[MAX_N] = {0};
    for (int e = 0; e < edge_count; ++e) {
        const size_t pos = edge_offset + 3 * (size_t)e;
        const int64_t u64 = input[pos], v64 = input[pos + 1], w64 = input[pos + 2];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 9) return -1;
        const int u = (int)u64, v = (int)v64;
        if (edge_seen[u][v]) return -1;
        edge_seen[u][v] = edge_seen[v][u] = 1;
        neighbor[u][degree[u]] = v; weight[u][degree[u]++] = (int)w64;
        neighbor[v][degree[v]] = u; weight[v][degree[v]++] = (int)w64;
        if (e >= base_edges) affected[u] = affected[v] = 1;
    }
    if (mode == 3) {
        for (int v = 0; v < n; ++v) if (degree[v] == 0) return -1;
    }

    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;
    int queue[MAX_N], next_queue[MAX_N], count = 0;
    uint8_t seen[MAX_N] = {0};

    if (mode == 1) {
        const int source = (int)source64;
        if (property[source] == -1) property[source] = 0;
        for (int v = 0; v < n; ++v) if (affected[v]) {
            const int64_t old_value = property[v];
            int64_t candidate = INF_VALUE;
            for (int j = 0; j < degree[v]; ++j) {
                const int u = neighbor[v][j];
                if (property[u] != -1 && property[u] + 1 < candidate)
                    candidate = property[u] + 1;
            }
            if (candidate != INF_VALUE && (candidate < old_value || old_value == -1)) {
                property[v] = candidate;
                for (int j = 0; j < degree[v]; ++j) {
                    const int u = neighbor[v][j];
                    const int64_t update = candidate + 1;
                    if (property[u] == -1 || update < property[u]) {
                        property[u] = update;
                        enqueue_once(u, queue, &count, seen);
                    }
                }
            }
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int u = queue[q];
                for (int j = 0; j < degree[u]; ++j) {
                    const int v = neighbor[u][j];
                    const int64_t update = property[u] + 1;
                    if (property[v] == -1 || update < property[v]) {
                        property[v] = update;
                        enqueue_once(v, next_queue, &next_count, next_seen);
                    }
                }
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
    } else if (mode == 2) {
        const int source = (int)source64;
        for (int v = 0; v < n; ++v) if (property[v] == -1)
            property[v] = (v == source) ? 0 : INF_VALUE;
        for (int v = 0; v < n; ++v) if (affected[v]) {
            const int64_t old_value = property[v];
            int64_t candidate = INF_VALUE;
            for (int j = 0; j < degree[v]; ++j) {
                const int u = neighbor[v][j];
                const int64_t next = property[u] + weight[v][j];
                if (next < candidate) candidate = next;
            }
            if (candidate < old_value && candidate != INF_VALUE) {
                property[v] = candidate;
                for (int j = 0; j < degree[v]; ++j)
                    enqueue_once(neighbor[v][j], queue, &count, seen);
            }
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int v = queue[q];
                int64_t candidate = INF_VALUE;
                for (int j = 0; j < degree[v]; ++j) {
                    const int u = neighbor[v][j];
                    const int64_t next = property[u] + weight[v][j];
                    if (next < candidate) candidate = next;
                }
                if (candidate < property[v] && candidate != INF_VALUE) {
                    property[v] = candidate;
                    for (int j = 0; j < degree[v]; ++j)
                        enqueue_once(neighbor[v][j], next_queue, &next_count, next_seen);
                }
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
    } else if (mode == 3) {
        const float damping = 0.85f;
        const float base_score = (1.0f - damping) / (float)n;
        float rank[MAX_N], contribution[MAX_N];
        for (int v = 0; v < n; ++v)
            rank[v] = property[v] == -1 ? 1.0f / (float)n : (float)property[v] / 1000000.0f;
        for (int v = 0; v < n; ++v) contribution[v] = rank[v] / (float)degree[v];
        for (int v = 0; v < n; ++v) if (affected[v]) {
            float incoming = 0.0f;
            for (int j = 0; j < degree[v]; ++j) incoming += contribution[neighbor[v][j]];
            const float old_rank = rank[v];
            rank[v] = base_score + damping * incoming;
            float difference = rank[v] - old_rank;
            if (difference < 0.0f) difference = -difference;
            if (difference > 1.0e-7f)
                for (int j = 0; j < degree[v]; ++j)
                    enqueue_once(neighbor[v][j], queue, &count, seen);
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            for (int v = 0; v < n; ++v) contribution[v] = rank[v] / (float)degree[v];
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int v = queue[q];
                float incoming = 0.0f;
                for (int j = 0; j < degree[v]; ++j) incoming += contribution[neighbor[v][j]];
                const float old_rank = rank[v];
                rank[v] = base_score + damping * incoming;
                float difference = rank[v] - old_rank;
                if (difference < 0.0f) difference = -difference;
                if (difference > 1.0e-7f)
                    for (int j = 0; j < degree[v]; ++j)
                        enqueue_once(neighbor[v][j], next_queue, &next_count, next_seen);
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
        for (int v = 0; v < n; ++v)
            property[v] = (int64_t)(rank[v] * 1000000.0f + 0.5f);
    } else if (mode == 4) {
        for (int v = 0; v < n; ++v) if (property[v] == -1) property[v] = v;
        for (int v = 0; v < n; ++v) if (affected[v]) {
            const int64_t old_value = property[v];
            int64_t candidate = old_value;
            for (int j = 0; j < degree[v]; ++j)
                if (property[neighbor[v][j]] < candidate) candidate = property[neighbor[v][j]];
            if (candidate < old_value || old_value == v) {
                property[v] = candidate;
                for (int j = 0; j < degree[v]; ++j)
                    enqueue_once(neighbor[v][j], queue, &count, seen);
            }
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int v = queue[q];
                const int64_t old_value = property[v];
                int64_t candidate = old_value;
                for (int j = 0; j < degree[v]; ++j)
                    if (property[neighbor[v][j]] < candidate) candidate = property[neighbor[v][j]];
                if (candidate < old_value) {
                    property[v] = candidate;
                    for (int j = 0; j < degree[v]; ++j)
                        enqueue_once(neighbor[v][j], next_queue, &next_count, next_seen);
                }
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
    } else if (mode == 5) {
        const int source = (int)source64;
        for (int v = 0; v < n; ++v) if (property[v] == -1)
            property[v] = (v == source) ? INF_VALUE : 0;
        for (int v = 0; v < n; ++v) if (affected[v]) {
            const int64_t old_value = property[v];
            int64_t candidate = 0;
            for (int j = 0; j < degree[v]; ++j) {
                const int u = neighbor[v][j];
                const int64_t path = property[u] < weight[v][j] ? property[u] : weight[v][j];
                if (path > candidate) candidate = path;
            }
            if (candidate > old_value) {
                property[v] = candidate;
                for (int j = 0; j < degree[v]; ++j)
                    enqueue_once(neighbor[v][j], queue, &count, seen);
            }
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int v = queue[q];
                const int64_t old_value = property[v];
                int64_t candidate = 0;
                for (int j = 0; j < degree[v]; ++j) {
                    const int u = neighbor[v][j];
                    const int64_t path = property[u] < weight[v][j] ? property[u] : weight[v][j];
                    if (path > candidate) candidate = path;
                }
                if (candidate > old_value) {
                    property[v] = candidate;
                    for (int j = 0; j < degree[v]; ++j)
                        enqueue_once(neighbor[v][j], next_queue, &next_count, next_seen);
                }
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
    } else {
        for (int v = 0; v < n; ++v) if (property[v] == -1) property[v] = v;
        for (int v = 0; v < n; ++v) if (affected[v]) {
            const int64_t old_value = property[v];
            int64_t candidate = old_value;
            for (int j = 0; j < degree[v]; ++j)
                if (property[neighbor[v][j]] > candidate) candidate = property[neighbor[v][j]];
            if (candidate > old_value || old_value == v) {
                property[v] = candidate;
                for (int j = 0; j < degree[v]; ++j)
                    enqueue_once(neighbor[v][j], queue, &count, seen);
            }
        }
        int rounds = 0;
        while (count != 0) {
            if (++rounds > MAX_ROUNDS) return -1;
            int next_count = 0;
            uint8_t next_seen[MAX_N] = {0};
            for (int q = 0; q < count; ++q) {
                const int v = queue[q];
                const int64_t old_value = property[v];
                int64_t candidate = old_value;
                for (int j = 0; j < degree[v]; ++j)
                    if (property[neighbor[v][j]] > candidate) candidate = property[neighbor[v][j]];
                if (candidate > old_value) {
                    property[v] = candidate;
                    for (int j = 0; j < degree[v]; ++j)
                        enqueue_once(neighbor[v][j], next_queue, &next_count, next_seen);
                }
            }
            for (int q = 0; q < next_count; ++q) queue[q] = next_queue[q];
            count = next_count;
        }
    }

    for (int v = 0; v < n; ++v) store_i64_le(output, 8 * (size_t)v, property[v]);
    return (int64_t)output_bytes;
}
