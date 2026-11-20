#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_D 4
#define MAX_INPUT 89
#define MAX_PARSEABLE 90
#define COORD_LIMIT 100
#define DISTANCE_RADIX INT64_C(160001)

int64_t graphai_gnns_hill_climbing(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_PARSEABLE) return -1;
    const int64_t n_value = input[0], d_value = input[1], start_value = input[2];
    const int64_t e_value = input[3], t_value = input[4];
    if (n_value < 2 || n_value > MAX_N || d_value < 1 || d_value > MAX_D ||
        start_value < 0 || start_value >= n_value || e_value < 1 || e_value >= n_value ||
        t_value < 0 || t_value > 16) return -1;
    const size_t n = (size_t)n_value, d = (size_t)d_value;
    if (length != 5 + n * d + n + d || length > MAX_INPUT) return -1;

    int64_t coordinates[MAX_N * MAX_D] = {0};
    for (size_t i = 0; i < n * d; ++i) {
        coordinates[i] = input[5 + i];
        if (coordinates[i] < -COORD_LIMIT || coordinates[i] > COORD_LIMIT) return -1;
    }
    const size_t mask_offset = 5 + n * d;
    int64_t masks[MAX_N] = {0};
    const int64_t allowed = (INT64_C(1) << n) - 1;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const int64_t mask = input[mask_offset + vertex];
        if (mask < 0 || (mask & ~allowed) != 0 || (mask & (INT64_C(1) << vertex)) != 0) return -1;
        masks[vertex] = mask;
    }
    const size_t query_offset = mask_offset + n;
    int64_t query[MAX_D] = {0};
    for (size_t axis = 0; axis < d; ++axis) {
        query[axis] = input[query_offset + axis];
        if (query[axis] < -COORD_LIMIT || query[axis] > COORD_LIMIT) return -1;
    }

    size_t current = (size_t)start_value;
    int64_t current_distance = 0;
    for (size_t axis = 0; axis < d; ++axis) {
        const int64_t delta = coordinates[current * d + axis] - query[axis];
        current_distance += delta * delta;
    }
    int64_t evaluations = 1, moves = 0;
    for (int64_t step = 0; step < t_value; ++step) {
        size_t best_vertex = current;
        int64_t best_distance = current_distance;
        int64_t inspected = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if ((masks[current] & (INT64_C(1) << vertex)) == 0) continue;
            int64_t distance = 0;
            for (size_t axis = 0; axis < d; ++axis) {
                const int64_t delta = coordinates[vertex * d + axis] - query[axis];
                distance += delta * delta;
            }
            ++evaluations;
            ++inspected;
            if (distance < best_distance || (distance == best_distance && vertex < best_vertex)) {
                best_distance = distance;
                best_vertex = vertex;
            }
            if (inspected == e_value) break;
        }
        if (best_distance >= current_distance) break;
        current = best_vertex;
        current_distance = best_distance;
        ++moves;
    }
    return (((evaluations * 17 + moves) * 16 + (int64_t)current) * DISTANCE_RADIX
            + current_distance);
}
