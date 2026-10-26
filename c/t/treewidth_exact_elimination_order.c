#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_EDGES = 28, MAX_INPUT = 58, MAX_OUTPUT = 72 };

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[offset + i] = (uint8_t)bits; bits >>= 8; }
}

int64_t treewidth_exact_elimination_order(const int64_t *values, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (!values || length < 2 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_N ||
        values[1] < 0 || values[1] > MAX_EDGES) return -1;
    const int n = (int)values[0], m = (int)values[1];
    if (m > n * (n - 1) / 2 || length != (size_t)(2 + 2 * m)) return -1;
    uint8_t base[MAX_N * MAX_N] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t a0 = values[2 + 2 * edge], b0 = values[3 + 2 * edge];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 >= b0) return -1;
        const int a = (int)a0, b = (int)b0;
        if (base[a * MAX_N + b]) return -1;
        base[a * MAX_N + b] = base[b * MAX_N + a] = 1;
    }
    int permutation[MAX_N], best_order[MAX_N];
    for (int i = 0; i < n; ++i) permutation[i] = i;
    int best_width = MAX_N + 1;
    for (;;) {
        uint8_t adjacent[MAX_N * MAX_N], active[MAX_N] = {0};
        for (int i = 0; i < MAX_N * MAX_N; ++i) adjacent[i] = base[i];
        for (int i = 0; i < n; ++i) active[i] = 1;
        int width = 0;
        for (int step = 0; step < n; ++step) {
            const int vertex = permutation[step];
            int neighbors[MAX_N], count = 0;
            for (int other = 0; other < n; ++other)
                if (active[other] && adjacent[vertex * MAX_N + other]) neighbors[count++] = other;
            if (count > width) width = count;
            for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
                const int a = neighbors[i], b = neighbors[j];
                adjacent[a * MAX_N + b] = adjacent[b * MAX_N + a] = 1;
            }
            active[vertex] = 0;
        }
        if (width < best_width) {
            best_width = width;
            for (int i = 0; i < n; ++i) best_order[i] = permutation[i];
        }
        int pivot = n - 2;
        while (pivot >= 0 && permutation[pivot] >= permutation[pivot + 1]) --pivot;
        if (pivot < 0) break;
        int successor = n - 1;
        while (permutation[successor] <= permutation[pivot]) --successor;
        int temporary = permutation[pivot]; permutation[pivot] = permutation[successor]; permutation[successor] = temporary;
        for (int left = pivot + 1, right = n - 1; left < right; ++left, --right) {
            temporary = permutation[left]; permutation[left] = permutation[right]; permutation[right] = temporary;
        }
    }
    const size_t bytes = 8 * (size_t)(n + 1);
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, best_width);
    for (int i = 0; i < n; ++i) put_i64(staged, 8 * (size_t)(i + 1), best_order[i]);
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
