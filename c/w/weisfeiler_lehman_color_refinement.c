#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_INPUT_LENGTH 9
#define INVALID_RESULT INT64_C(-1)
#define DEGREE_COLOR_PLACE INT64_C(43046721)

static unsigned popcount_u64(uint64_t value) {
    unsigned count = 0;
    while (value != 0) {
        count += (unsigned)(value & 1U);
        value >>= 1U;
    }
    return count;
}

int64_t weisfeiler_lehman_color_refinement(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH + 1) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > MAX_VERTICES) return INVALID_RESULT;
    const unsigned n = (unsigned)input[0];
    if (length != (size_t)(1 + n)) return INVALID_RESULT;

    uint64_t adjacency[MAX_VERTICES] = {0};
    const uint64_t allowed = (UINT64_C(1) << n) - 1U;
    int64_t colors[MAX_VERTICES] = {0};
    int64_t next_colors[MAX_VERTICES] = {0};
    unsigned class_count = 0;
    for (unsigned vertex = 0; vertex < n; ++vertex) {
        if (input[1 + vertex] < 0) return INVALID_RESULT;
        adjacency[vertex] = (uint64_t)input[1 + vertex];
        if ((adjacency[vertex] & ~allowed) != 0 ||
            (adjacency[vertex] & (UINT64_C(1) << vertex)) != 0) return INVALID_RESULT;
        colors[vertex] = (int64_t)popcount_u64(adjacency[vertex]);
        int first_degree = 1;
        for (unsigned prior = 0; prior < vertex; ++prior) {
            if (((int64_t)popcount_u64(adjacency[prior])) == colors[vertex]) first_degree = 0;
            if (((adjacency[vertex] >> prior) & 1U) != ((adjacency[prior] >> vertex) & 1U))
                return INVALID_RESULT;
        }
        if (first_degree) ++class_count;
    }
    if (n == 0) return 0;

    for (;;) {
        int64_t keys[MAX_VERTICES];
        int64_t unique_keys[MAX_VERTICES];
        unsigned unique_count = 0;
        for (unsigned vertex = 0; vertex < n; ++vertex) {
            int64_t neighbor_colors[MAX_VERTICES];
            unsigned neighbor_count = 0;
            for (unsigned neighbor = 0; neighbor < n; ++neighbor) {
                if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) == 0) continue;
                int64_t value = colors[neighbor];
                unsigned position = neighbor_count;
                while (position > 0 && neighbor_colors[position - 1] > value) {
                    neighbor_colors[position] = neighbor_colors[position - 1];
                    --position;
                }
                neighbor_colors[position] = value;
                ++neighbor_count;
            }
            int64_t suffix = 0;
            for (unsigned slot = 0; slot < MAX_VERTICES; ++slot) {
                suffix *= 9;
                if (slot < neighbor_count) suffix += neighbor_colors[slot] + 1;
            }
            keys[vertex] = colors[vertex] * DEGREE_COLOR_PLACE + suffix;

            int seen = 0;
            for (unsigned prior = 0; prior < vertex; ++prior) {
                if (keys[prior] == keys[vertex]) seen = 1;
            }
            if (!seen) unique_keys[unique_count++] = keys[vertex];
        }

        for (unsigned index = 1; index < unique_count; ++index) {
            int64_t value = unique_keys[index];
            unsigned position = index;
            while (position > 0 && unique_keys[position - 1] > value) {
                unique_keys[position] = unique_keys[position - 1];
                --position;
            }
            unique_keys[position] = value;
        }
        for (unsigned vertex = 0; vertex < n; ++vertex) {
            unsigned rank = 0;
            while (unique_keys[rank] != keys[vertex]) ++rank;
            next_colors[vertex] = (int64_t)rank;
        }
        if (unique_count == class_count) {
            for (unsigned vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
            break;
        }
        for (unsigned vertex = 0; vertex < n; ++vertex) colors[vertex] = next_colors[vertex];
        class_count = unique_count;
    }

    int64_t packed = 0;
    int64_t place = 1;
    for (unsigned vertex = 0; vertex < n; ++vertex) {
        packed += colors[vertex] * place;
        place *= 9;
    }
    return packed;
}
