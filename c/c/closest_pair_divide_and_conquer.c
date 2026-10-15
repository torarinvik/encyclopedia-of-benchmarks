/* Deterministic divide-and-conquer closest pair over bounded integer points. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_POINTS 1024

typedef struct {
    int64_t x;
    int64_t y;
} point_t;

typedef struct {
    bool valid;
    uint64_t distance_squared;
    size_t first;
    size_t second;
} pair_result_t;

static bool before(const size_t left, const size_t right, const point_t *points, bool by_y)
{
    if (by_y) {
        if (points[left].y != points[right].y) return points[left].y < points[right].y;
        if (points[left].x != points[right].x) return points[left].x < points[right].x;
    } else {
        if (points[left].x != points[right].x) return points[left].x < points[right].x;
        if (points[left].y != points[right].y) return points[left].y < points[right].y;
    }
    return left < right;
}

static void sort_indices(size_t *indices, size_t *scratch, size_t begin, size_t end,
                         const point_t *points, bool by_y)
{
    if (end - begin < 2) return;
    const size_t middle = begin + (end - begin) / 2;
    sort_indices(indices, scratch, begin, middle, points, by_y);
    sort_indices(indices, scratch, middle, end, points, by_y);
    size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end) {
        if (before(indices[right], indices[left], points, by_y)) scratch[out++] = indices[right++];
        else scratch[out++] = indices[left++];
    }
    while (left < middle) scratch[out++] = indices[left++];
    while (right < end) scratch[out++] = indices[right++];
    memcpy(indices + begin, scratch + begin, (end - begin) * sizeof(*indices));
}

static uint64_t squared_distance(size_t left, size_t right, const point_t *points)
{
    const int64_t dx = points[left].x - points[right].x;
    const int64_t dy = points[left].y - points[right].y;
    return (uint64_t)(dx * dx) + (uint64_t)(dy * dy);
}

static pair_result_t choose(pair_result_t left, pair_result_t right)
{
    if (!left.valid) return right;
    if (!right.valid) return left;
    if (left.distance_squared < right.distance_squared) return left;
    if (right.distance_squared < left.distance_squared) return right;
    if (left.first < right.first || (left.first == right.first && left.second <= right.second)) return left;
    return right;
}

static pair_result_t candidate(size_t left, size_t right, const point_t *points)
{
    if (left > right) {
        const size_t temporary = left;
        left = right;
        right = temporary;
    }
    return (pair_result_t){true, squared_distance(left, right, points), left, right};
}

static pair_result_t search(const size_t *x_order, size_t begin, size_t end,
                            const size_t *y_order, size_t y_count,
                            const size_t *rank, const point_t *points)
{
    const size_t count = end - begin;
    if (count <= 3) {
        pair_result_t best = {false, 0, 0, 0};
        for (size_t i = begin; i < end; ++i)
            for (size_t j = i + 1; j < end; ++j)
                best = choose(best, candidate(x_order[i], x_order[j], points));
        return best;
    }

    const size_t middle = begin + count / 2;
    size_t y_left[MAX_POINTS], y_right[MAX_POINTS];
    size_t left_count = 0, right_count = 0;
    for (size_t i = 0; i < y_count; ++i) {
        const size_t point = y_order[i];
        if (rank[point] < middle) y_left[left_count++] = point;
        else y_right[right_count++] = point;
    }

    pair_result_t best = choose(
        search(x_order, begin, middle, y_left, left_count, rank, points),
        search(x_order, middle, end, y_right, right_count, rank, points));

    size_t strip[MAX_POINTS];
    size_t strip_count = 0;
    const int64_t middle_x = points[x_order[middle]].x;
    for (size_t i = 0; i < y_count; ++i) {
        const size_t point = y_order[i];
        const int64_t dx = points[point].x - middle_x;
        if ((uint64_t)(dx * dx) <= best.distance_squared) strip[strip_count++] = point;
    }

    for (size_t i = 0; i < strip_count; ++i) {
        for (size_t j = i + 1; j < strip_count; ++j) {
            const int64_t dy = points[strip[j]].y - points[strip[i]].y;
            if ((uint64_t)(dy * dy) > best.distance_squared) break;
            best = choose(best, candidate(strip[i], strip[j], points));
        }
    }
    return best;
}

int64_t closest_pair_divide_and_conquer(const int64_t *values, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == NULL)) return -1;
    const size_t point_count = length / 2;

    point_t points[MAX_POINTS];
    size_t x_order[MAX_POINTS], y_order[MAX_POINTS], rank[MAX_POINTS], scratch[MAX_POINTS];
    for (size_t i = 0; i < point_count; ++i) {
        const int64_t x = values[2 * i], y = values[2 * i + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        points[i] = (point_t){x, y};
        x_order[i] = i;
        y_order[i] = i;
    }
    if (point_count < 2) return 0;
    sort_indices(x_order, scratch, 0, point_count, points, false);
    for (size_t i = 0; i < point_count; ++i) rank[x_order[i]] = i;

    /* Duplicate coordinates make the optimum zero; resolve its tie directly. */
    pair_result_t duplicate = {false, 0, 0, 0};
    for (size_t begin = 0; begin < point_count;) {
        size_t end = begin + 1;
        const size_t anchor = x_order[begin];
        while (end < point_count && points[x_order[end]].x == points[anchor].x &&
               points[x_order[end]].y == points[anchor].y) ++end;
        if (end - begin > 1) {
            size_t first = SIZE_MAX, second = SIZE_MAX;
            for (size_t i = begin; i < end; ++i) {
                const size_t id = x_order[i];
                if (id < first) { second = first; first = id; }
                else if (id < second) second = id;
            }
            duplicate = choose(duplicate, (pair_result_t){true, 0, first, second});
        }
        begin = end;
    }
    if (duplicate.valid) {
        if (output == NULL || output_capacity < 8) return -2;
        for (size_t byte = 0; byte < 4; ++byte) {
            output[byte] = (uint8_t)((uint32_t)duplicate.first >> (8 * byte));
            output[4 + byte] = (uint8_t)((uint32_t)duplicate.second >> (8 * byte));
        }
        return 2;
    }

    sort_indices(y_order, scratch, 0, point_count, points, true);
    const pair_result_t best = search(x_order, 0, point_count, y_order, point_count, rank, points);
    if (!best.valid) return -1;
    if (output == NULL || output_capacity < 8) return -2;
    for (size_t byte = 0; byte < 4; ++byte) {
        output[byte] = (uint8_t)((uint32_t)best.first >> (8 * byte));
        output[4 + byte] = (uint8_t)((uint32_t)best.second >> (8 * byte));
    }
    return 2;
}
