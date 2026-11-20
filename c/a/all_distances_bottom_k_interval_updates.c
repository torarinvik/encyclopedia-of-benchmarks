#include <stddef.h>
#include <stdint.h>

#define ABKI_MAX_N 32
#define ABKI_MIN_K 2
#define ABKI_MAX_K 4
#define ABKI_MAX_INPUT 99
#define ABKI_MAX_WORDS 97
#define ABKI_DISTANCE_LIMIT 1000000
#define ABKI_END 1000001

static void abki_put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t all_distances_bottom_k_interval_updates(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > ABKI_MAX_INPUT) return -1;
    const int64_t n0 = input[0], k0 = input[1];
    if (n0 < 2 || n0 > ABKI_MAX_N || k0 < ABKI_MIN_K || k0 > ABKI_MAX_K
            || k0 > n0) return -1;
    const size_t n = (size_t)n0, k = (size_t)k0;
    if (length != 2 + 3 * n) return -1;

    int64_t item[ABKI_MAX_N], distance[ABKI_MAX_N], rank[ABKI_MAX_N];
    uint8_t seen_id[ABKI_MAX_N] = {0}, seen_rank[ABKI_MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        item[i] = input[2 + 3 * i];
        distance[i] = input[3 + 3 * i];
        rank[i] = input[4 + 3 * i];
        if (item[i] < 0 || item[i] >= n0 || seen_id[(size_t)item[i]]
                || rank[i] < 0 || rank[i] >= n0 || seen_rank[(size_t)rank[i]]
                || distance[i] < 0 || distance[i] > ABKI_DISTANCE_LIMIT)
            return -1;
        seen_id[(size_t)item[i]] = 1;
        seen_rank[(size_t)rank[i]] = 1;
        for (size_t j = 0; j < i; ++j)
            if (distance[j] == distance[i]) return -1;
    }
    for (size_t i = 1; i < k; ++i)
        if (distance[i - 1] >= distance[i]) return -1;
    for (size_t i = k; i < n; ++i)
        if (distance[i] <= distance[k - 1]) return -1;

    int64_t interval_id[ABKI_MAX_N], interval_rank[ABKI_MAX_N];
    int64_t start[ABKI_MAX_N], end[ABKI_MAX_N];
    size_t interval_count = k;
    for (size_t i = 0; i < k; ++i) {
        interval_id[i] = item[i];
        interval_rank[i] = rank[i];
        start[i] = distance[i];
        end[i] = ABKI_END;
    }
    for (size_t i = k; i < n; ++i) {
        size_t worst = ABKI_MAX_N;
        size_t active_count = 0;
        for (size_t q = 0; q < interval_count; ++q) {
            if (start[q] <= distance[i] && distance[i] < end[q]) {
                ++active_count;
                if (worst == ABKI_MAX_N || interval_rank[q] > interval_rank[worst])
                    worst = q;
            }
        }
        if (active_count != k || worst == ABKI_MAX_N) return -1;
        if (rank[i] >= interval_rank[worst]) continue;

        int64_t cursor = end[worst];
        end[worst] = distance[i];
        while (cursor < ABKI_END) {
            size_t next_worst = ABKI_MAX_N;
            for (size_t q = 0; q < interval_count; ++q) {
                if (start[q] <= cursor && cursor < end[q]
                        && (next_worst == ABKI_MAX_N
                            || interval_rank[q] > interval_rank[next_worst]))
                    next_worst = q;
            }
            if (next_worst == ABKI_MAX_N || interval_rank[next_worst] <= rank[i])
                break;
            const int64_t next_end = end[next_worst];
            end[next_worst] = cursor;
            cursor = next_end;
        }
        interval_id[interval_count] = item[i];
        interval_rank[interval_count] = rank[i];
        start[interval_count] = distance[i];
        end[interval_count] = cursor;
        ++interval_count;
    }

    size_t order[ABKI_MAX_N], out_count = 0;
    for (size_t i = 0; i < interval_count; ++i)
        if (start[i] < end[i]) order[out_count++] = i;
    for (size_t i = 1; i < out_count; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && (start[order[j - 1]] > start[key]
                || (start[order[j - 1]] == start[key]
                    && interval_id[order[j - 1]] > interval_id[key]))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }

    int64_t staged[ABKI_MAX_WORDS] = {0};
    staged[0] = (int64_t)out_count;
    for (size_t i = 0; i < out_count; ++i) {
        const size_t source = order[i];
        staged[1 + 3 * i] = interval_id[source];
        staged[2 + 3 * i] = start[source];
        staged[3 + 3 * i] = end[source];
    }
    const size_t bytes = 8 * (1 + 3 * out_count);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < 1 + 3 * out_count; ++word)
        abki_put_i64(output, word, staged[word]);
    return (int64_t)bytes;
}
