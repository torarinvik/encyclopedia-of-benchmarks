/* Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 24, MAX_INPUT = 52, MAX_CUTOFF = 128 };

static uint64_t hash64(uint64_t value) {
    uint64_t mixed = value * UINT64_C(3935559000370003845) + UINT64_C(2691343689449507681);
    mixed ^= mixed >> 21;
    mixed ^= mixed << 37;
    mixed ^= mixed >> 4;
    mixed *= UINT64_C(4768777513237032717);
    mixed ^= mixed << 20;
    mixed ^= mixed >> 41;
    mixed ^= mixed << 5;
    return mixed;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t query(size_t vertex, const size_t *degree,
                     const size_t *neighbors, const uint64_t *priority,
                     size_t *work, size_t cutoff) {
    for (size_t index = 0; index < degree[vertex]; ++index) {
        if (*work == cutoff) return -1;
        const size_t neighbor = neighbors[vertex * MAX_N + index];
        ++*work;
        if (priority[vertex] < priority[neighbor] ||
            (priority[vertex] == priority[neighbor] && vertex <= neighbor)) break;
        const int64_t status = query(neighbor, degree, neighbors, priority, work, cutoff);
        if (status == 1) return 0;
        if (status == -1) return -1;
    }
    return 1;
}

int64_t gbbs_yoshida_query_mis(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], root64 = input[2], cutoff64 = input[3];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        root64 < 0 || root64 >= n64 || cutoff64 < 0 || cutoff64 > MAX_CUTOFF ||
        length != 4 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t degree[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[4 + 2 * edge], v64 = input[5 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++degree[u]; ++degree[v];
    }
    if (output == NULL || capacity < 16) return -2;

    uint64_t priority[MAX_N];
    size_t neighbors[MAX_N][MAX_N] = {{0}};
    for (size_t vertex = 0; vertex < n; ++vertex) priority[vertex] = hash64((uint64_t)vertex);
    for (size_t vertex = 0; vertex < n; ++vertex) {
        size_t inserted = 0;
        for (size_t other = 0; other < n; ++other) if (adjacent[vertex][other]) {
            size_t position = inserted;
            while (position > 0) {
                const size_t previous = neighbors[vertex][position - 1];
                if (priority[previous] < priority[other] ||
                    (priority[previous] == priority[other] && previous < other)) break;
                neighbors[vertex][position] = previous;
                --position;
            }
            neighbors[vertex][position] = other;
            ++inserted;
        }
    }
    size_t work = 0;
    const int64_t status = query((size_t)root64, degree, &neighbors[0][0],
                                 priority, &work, (size_t)cutoff64);
    store_i64_le(output, 0, status);
    store_i64_le(output, 8, (int64_t)work);
    return 16;
}
