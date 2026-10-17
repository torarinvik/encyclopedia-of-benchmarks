#include <stddef.h>
#include <stdint.h>

#define KC_MAX_POINTS 8
#define KC_MAX_DISTANCE 1000000
#define KC_JAVA_INT_MAX 2147483647
#define KC_MAX_INPUT_LENGTH (2 + KC_MAX_POINTS * KC_MAX_POINTS)

int64_t kcenters(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > KC_MAX_INPUT_LENGTH) return -1;
    const int64_t point_count = values[0], center_count = values[1];
    if (point_count < 1 || point_count > KC_MAX_POINTS || center_count < 1 || center_count > point_count ||
        length != (size_t)(2 + point_count * point_count)) return -1;
    for (int64_t row = 0; row < point_count; ++row) {
        for (int64_t column = 0; column < point_count; ++column) {
            const int64_t distance = values[2 + row * point_count + column];
            if (distance < 0 || distance > KC_MAX_DISTANCE || (row == column && distance != 0) ||
                distance != values[2 + column * point_count + row]) return -1;
        }
    }

    int selected[KC_MAX_POINTS] = {0};
    int64_t max_distance[KC_MAX_POINTS];
    for (int64_t point = 0; point < point_count; ++point) max_distance[point] = KC_JAVA_INT_MAX;
    selected[0] = 1;
    for (int64_t point = 1; point < point_count; ++point) {
        const int64_t distance = values[2 + point];
        if (distance < max_distance[point]) max_distance[point] = distance;
    }
    for (int64_t center = 1; center < center_count; ++center) {
        int64_t farthest = -1;
        for (int64_t point = 0; point < point_count; ++point)
            if (!selected[point] && (farthest == -1 || max_distance[point] > max_distance[farthest])) farthest = point;
        selected[farthest] = 1;
        for (int64_t point = 0; point < point_count; ++point) {
            const int64_t distance = values[2 + farthest * point_count + point];
            if (distance < max_distance[point]) max_distance[point] = distance;
        }
    }
    int64_t result = 0;
    for (int64_t point = 0; point < point_count; ++point)
        if (max_distance[point] > result) result = max_distance[point];
    return result;
}
