#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define MAX_PACKED_LENGTH 16

static int64_t distance_i64(int64_t a, int64_t b)
{
    return a >= b ? a - b : b - a;
}

int64_t k_medoids(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 3 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const int64_t point_count = packed[0], medoid_count = packed[1], max_iter = packed[2];
    if (point_count < 2 || point_count > 8 || medoid_count < 1 || medoid_count > 4 ||
        medoid_count > point_count || max_iter < 1 || max_iter > 16 ||
        length != (size_t)(3 + medoid_count + point_count)) return INVALID_RESULT;
    const size_t n = (size_t)point_count, k = (size_t)medoid_count;

    int64_t medoids[4] = {0};
    int64_t points[8] = {0};
    int64_t labels[8] = {0};
    for (size_t slot = 0; slot < k; ++slot) {
        medoids[slot] = packed[3 + slot];
        if (medoids[slot] < 0 || medoids[slot] >= point_count) return INVALID_RESULT;
        for (size_t earlier = 0; earlier < slot; ++earlier)
            if (medoids[earlier] == medoids[slot]) return INVALID_RESULT;
    }
    for (size_t i = 0; i < n; ++i) {
        points[i] = packed[3 + k + i];
        if (points[i] < -16 || points[i] > 16) return INVALID_RESULT;
        for (size_t earlier = 0; earlier < i; ++earlier)
            if (points[earlier] == points[i]) return INVALID_RESULT;
    }

    for (int64_t iteration = 0; iteration < max_iter; ++iteration) {
        for (size_t i = 0; i < n; ++i) {
            size_t best_slot = 0;
            int64_t best_distance = distance_i64(points[i], points[(size_t)medoids[0]]);
            for (size_t slot = 1; slot < k; ++slot) {
                const int64_t distance = distance_i64(points[i], points[(size_t)medoids[slot]]);
                if (distance < best_distance) { best_distance = distance; best_slot = slot; }
            }
            labels[i] = (int64_t)best_slot;
        }

        int64_t updated[4] = {0};
        for (size_t slot = 0; slot < k; ++slot) {
            size_t first = n;
            for (size_t i = 0; i < n; ++i) if (labels[i] == (int64_t)slot) { first = i; break; }
            if (first == n) return INVALID_RESULT;
            size_t best_index = first;
            int64_t best_cost = 0;
            for (size_t i = 0; i < n; ++i)
                if (labels[i] == (int64_t)slot) best_cost += distance_i64(points[first], points[i]);
            for (size_t candidate = first + 1; candidate < n; ++candidate) {
                if (labels[candidate] != (int64_t)slot) continue;
                int64_t cost = 0;
                for (size_t i = 0; i < n; ++i)
                    if (labels[i] == (int64_t)slot) cost += distance_i64(points[candidate], points[i]);
                if (cost < best_cost) { best_cost = cost; best_index = candidate; }
            }
            updated[slot] = (int64_t)best_index;
        }

        int changed = 0;
        for (size_t slot = 0; slot < k; ++slot) if (updated[slot] != medoids[slot]) changed = 1;
        if (!changed) break;
        for (size_t slot = 0; slot < k; ++slot) medoids[slot] = updated[slot];
    }

    int64_t result = 0;
    for (size_t slot = 0; slot < k; ++slot) result |= medoids[slot] << (3 * slot);
    for (size_t i = 0; i < n; ++i) result |= labels[i] << (12 + 2 * i);
    return result;
}
