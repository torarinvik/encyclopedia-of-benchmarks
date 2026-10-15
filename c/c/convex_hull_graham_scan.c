/* Graham scan over bounded integer points; keep boundary-collinear points. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 1024

typedef struct {
    int64_t x;
    int64_t y;
    size_t original_index;
} point_t;

static int64_t cross(const point_t *a, const point_t *b, const point_t *c)
{
    return (b->x - a->x) * (c->y - a->y) - (b->y - a->y) * (c->x - a->x);
}

static int64_t radius_squared(const point_t *pivot, const point_t *point)
{
    const int64_t dx = point->x - pivot->x;
    const int64_t dy = point->y - pivot->y;
    return dx * dx + dy * dy;
}

static bool before_xy(size_t left, size_t right, const point_t *points)
{
    if (points[left].x != points[right].x) return points[left].x < points[right].x;
    if (points[left].y != points[right].y) return points[left].y < points[right].y;
    return points[left].original_index < points[right].original_index;
}

static bool before_angle(size_t left, size_t right, const point_t *points, size_t pivot_index)
{
    const point_t *pivot = &points[pivot_index];
    const int64_t turn = cross(pivot, &points[left], &points[right]);
    if (turn != 0) return turn > 0;
    const int64_t left_radius = radius_squared(pivot, &points[left]);
    const int64_t right_radius = radius_squared(pivot, &points[right]);
    if (left_radius != right_radius) return left_radius < right_radius;
    return points[left].original_index < points[right].original_index;
}

static void merge_sort(size_t *items, size_t *scratch, size_t begin, size_t end,
                       const point_t *points, size_t pivot_index, bool by_angle)
{
    if (end - begin < 2) return;
    const size_t middle = begin + (end - begin) / 2;
    merge_sort(items, scratch, begin, middle, points, pivot_index, by_angle);
    merge_sort(items, scratch, middle, end, points, pivot_index, by_angle);
    size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end) {
        const bool right_before = by_angle
            ? before_angle(items[right], items[left], points, pivot_index)
            : before_xy(items[right], items[left], points);
        scratch[out++] = right_before ? items[right++] : items[left++];
    }
    while (left < middle) scratch[out++] = items[left++];
    while (right < end) scratch[out++] = items[right++];
    for (size_t index = begin; index < end; ++index) items[index] = scratch[index];
}

int64_t convex_hull_graham_scan(const int64_t *values, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == NULL)) return -1;
    const size_t point_count = length / 2;
    point_t input_points[MAX_POINTS], points[MAX_POINTS];
    size_t order[MAX_POINTS], scratch[MAX_POINTS], hull[MAX_POINTS];

    for (size_t index = 0; index < point_count; ++index) {
        const int64_t x = values[2 * index], y = values[2 * index + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        input_points[index] = (point_t){x, y, index};
        order[index] = index;
    }
    if (point_count == 0) return 0;

    merge_sort(order, scratch, 0, point_count, input_points, 0, false);
    size_t unique_count = 0;
    for (size_t index = 0; index < point_count; ++index) {
        const point_t point = input_points[order[index]];
        if (unique_count == 0 || points[unique_count - 1].x != point.x ||
            points[unique_count - 1].y != point.y) {
            points[unique_count++] = point;
        }
    }
    if (unique_count == 1) {
        if (output == NULL || output_capacity < 4) return -2;
        const uint32_t id = (uint32_t)points[0].original_index;
        for (size_t byte = 0; byte < 4; ++byte) output[byte] = (uint8_t)(id >> (8 * byte));
        return 1;
    }

    size_t pivot_index = 0;
    for (size_t index = 1; index < unique_count; ++index) {
        if (points[index].y < points[pivot_index].y ||
            (points[index].y == points[pivot_index].y && points[index].x < points[pivot_index].x))
            pivot_index = index;
    }
    for (size_t index = 0; index < unique_count; ++index) order[index] = index;
    merge_sort(order, scratch, 0, unique_count, points, pivot_index, true);

    bool all_collinear = true;
    for (size_t index = 2; index < unique_count; ++index) {
        if (cross(&points[pivot_index], &points[order[1]], &points[order[index]]) != 0) {
            all_collinear = false;
            break;
        }
    }
    if (!all_collinear) {
        /* The final ray is the closing hull edge; visit its farthest point first. */
        size_t final_ray_begin = unique_count - 1;
        while (final_ray_begin > 1 &&
               cross(&points[pivot_index], &points[order[final_ray_begin - 1]],
                     &points[order[unique_count - 1]]) == 0)
            --final_ray_begin;
        for (size_t left = final_ray_begin, right = unique_count - 1; left < right; ++left, --right) {
            const size_t temporary = order[left];
            order[left] = order[right];
            order[right] = temporary;
        }
    }

    size_t hull_count = 0;
    for (size_t index = 0; index < unique_count; ++index) {
        const size_t point = order[index];
        while (hull_count >= 2 &&
               cross(&points[hull[hull_count - 2]], &points[hull[hull_count - 1]], &points[point]) < 0)
            --hull_count;
        hull[hull_count++] = point;
    }
    if (output == NULL || output_capacity < 4 * hull_count) return -2;
    for (size_t index = 0; index < hull_count; ++index) {
        const uint32_t id = (uint32_t)points[hull[index]].original_index;
        for (size_t byte = 0; byte < 4; ++byte)
            output[4 * index + byte] = (uint8_t)(id >> (8 * byte));
    }
    return (int64_t)hull_count;
}
