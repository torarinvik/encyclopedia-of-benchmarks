#include <stddef.h>
#include <stdint.h>

#define STLM_N 64
#define STLM_CELLS (STLM_N * STLM_N)

static void stlm_add(size_t map, size_t color, int64_t amount,
                     const int64_t *labels, int64_t *frequencies,
                     size_t *keys, size_t *map_lengths,
                     int64_t *maximum, int64_t *mode_sum) {
    size_t cell = map * STLM_N + color;
    int64_t old = frequencies[cell];
    if (old == 0) keys[map * STLM_N + map_lengths[map]++] = color;
    if (old > 0 && old == maximum[map]) mode_sum[map] -= labels[color];
    int64_t updated = old + amount;
    if (updated > maximum[map]) {
        maximum[map] = updated;
        mode_sum[map] = labels[color];
    } else if (updated == maximum[map]) {
        mode_sum[map] += labels[color];
    }
    frequencies[cell] = updated;
}

static void stlm_put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t small_to_large_subtree_color_mode_sum(const int64_t *input,
                                               size_t length,
                                               uint8_t *output,
                                               size_t capacity) {
    if (input == NULL || length < 2 || length > 129) return -1;
    int64_t n_value = input[0];
    if (n_value < 1 || n_value > STLM_N || length != (size_t)(2 * n_value)) return -1;
    size_t n = (size_t)n_value;
    size_t parent[STLM_N] = {0};
    for (size_t vertex = 1; vertex < n; ++vertex) {
        int64_t p = input[vertex];
        if (p < 0 || p >= (int64_t)vertex) return -1;
        parent[vertex] = (size_t)p;
    }
    int64_t sorted[STLM_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        int64_t color = input[n + vertex];
        if (color < -1000 || color > 1000) return -1;
        sorted[vertex] = color;
    }
    for (size_t i = 1; i < n; ++i) {
        int64_t value = sorted[i];
        size_t j = i;
        while (j > 0 && sorted[j - 1] > value) {
            sorted[j] = sorted[j - 1];
            --j;
        }
        sorted[j] = value;
    }
    int64_t labels[STLM_N];
    size_t distinct = 0;
    for (size_t i = 0; i < n; ++i)
        if (distinct == 0 || labels[distinct - 1] != sorted[i]) labels[distinct++] = sorted[i];
    size_t color_index[STLM_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        size_t index = 0;
        while (labels[index] != input[n + vertex]) ++index;
        color_index[vertex] = index;
    }

    if (output == NULL || capacity < 8 * n) return -2;
    int64_t frequencies[STLM_CELLS] = {0};
    size_t keys[STLM_CELLS] = {0};
    size_t map_lengths[STLM_N] = {0}, map_id[STLM_N] = {0};
    int64_t maximum[STLM_N] = {0}, mode_sum[STLM_N] = {0};
    int64_t answers[STLM_N] = {0};
    for (size_t vertex = n; vertex-- > 0;) {
        size_t largest_child = n;
        for (size_t child = vertex + 1; child < n; ++child)
            if (parent[child] == vertex &&
                (largest_child == n || map_lengths[map_id[child]] > map_lengths[map_id[largest_child]]))
                largest_child = child;
        size_t map = largest_child == n ? vertex : map_id[largest_child];
        for (size_t child = vertex + 1; child < n; ++child) {
            if (parent[child] != vertex || child == largest_child) continue;
            size_t small = map_id[child];
            for (size_t i = 0; i < map_lengths[small]; ++i) {
                size_t color = keys[small * STLM_N + i];
                int64_t amount = frequencies[small * STLM_N + color];
                stlm_add(map, color, amount, labels, frequencies, keys,
                         map_lengths, maximum, mode_sum);
            }
        }
        stlm_add(map, color_index[vertex], 1, labels, frequencies, keys,
                 map_lengths, maximum, mode_sum);
        map_id[vertex] = map;
        answers[vertex] = mode_sum[map];
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        stlm_put_i64(output, vertex * 8, answers[vertex]);
    return (int64_t)(8 * n);
}
