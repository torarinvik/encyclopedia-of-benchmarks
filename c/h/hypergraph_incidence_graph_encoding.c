#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define HIGE_MAX_N 8
#define HIGE_MAX_M 12
#define HIGE_MAX_INPUT 111

static void hige_put(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t hypergraph_incidence_graph_encoding(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > HIGE_MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > HIGE_MAX_N || m64 < 0 || m64 > HIGE_MAX_M) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    bool incidence[HIGE_MAX_N][HIGE_MAX_M] = {{false}};
    size_t offset = 2;
    for (size_t edge = 0; edge < m; ++edge) {
        if (offset >= length) return -1;
        const int64_t size64 = input[offset++];
        if (size64 < 0 || size64 > n64 || (uint64_t)size64 > length - offset) return -1;
        for (size_t item = 0; item < (size_t)size64; ++item) {
            const int64_t vertex64 = input[offset++];
            if (vertex64 < 0 || vertex64 >= n64) return -1;
            const size_t vertex = (size_t)vertex64;
            if (incidence[vertex][edge]) return -1;
            incidence[vertex][edge] = true;
        }
    }
    if (offset != length) return -1;

    size_t count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex)
        for (size_t edge = 0; edge < m; ++edge)
            if (incidence[vertex][edge]) ++count;
    const size_t nodes = n + m;
    const size_t bytes = 8 * (2 + nodes + 2 * count);
    if (output == NULL || capacity < bytes) return -2;

    hige_put(output, 0, (int64_t)nodes);
    hige_put(output, 8, (int64_t)count);
    size_t word = 2;
    for (size_t vertex = 0; vertex < n; ++vertex) hige_put(output, 8 * word++, 0);
    for (size_t edge = 0; edge < m; ++edge) hige_put(output, 8 * word++, 1);
    for (size_t vertex = 0; vertex < n; ++vertex)
        for (size_t edge = 0; edge < m; ++edge)
            if (incidence[vertex][edge]) {
                hige_put(output, 8 * word++, (int64_t)vertex);
                hige_put(output, 8 * word++, (int64_t)(n + edge));
            }
    return (int64_t)bytes;
}
