/* Quickhull over bounded integer points; emit extreme vertices in x/y order. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 1024

typedef struct { int64_t x, y; size_t id; } point_t;

static bool point_before(const point_t *left, const point_t *right)
{
    if (left->x != right->x) return left->x < right->x;
    if (left->y != right->y) return left->y < right->y;
    return left->id < right->id;
}

static int64_t cross(const point_t *a, const point_t *b, const point_t *c)
{
    return (b->x - a->x) * (c->y - a->y) - (b->y - a->y) * (c->x - a->x);
}

static void sort_points(point_t *points, point_t *scratch, size_t begin, size_t end)
{
    if (end - begin < 2) return;
    const size_t middle = begin + (end - begin) / 2;
    sort_points(points, scratch, begin, middle);
    sort_points(points, scratch, middle, end);
    size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end)
        scratch[out++] = point_before(&points[right], &points[left]) ? points[right++] : points[left++];
    while (left < middle) scratch[out++] = points[left++];
    while (right < end) scratch[out++] = points[right++];
    for (size_t index = begin; index < end; ++index) points[index] = scratch[index];
}

static void quick_hull(const point_t *points, size_t count, size_t left, size_t right,
                       bool *on_hull)
{
    size_t farthest = SIZE_MAX;
    int64_t greatest_area = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t area = cross(&points[left], &points[right], &points[index]);
        if (area > greatest_area) { greatest_area = area; farthest = index; }
    }
    if (farthest == SIZE_MAX) return;
    on_hull[farthest] = true;
    quick_hull(points, count, left, farthest, on_hull);
    quick_hull(points, count, farthest, right, on_hull);
}

int64_t convex_hull_quickhull(const int64_t *values, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == NULL)) return -1;
    const size_t input_count = length / 2;
    point_t points[MAX_POINTS], scratch[MAX_POINTS];
    for (size_t index = 0; index < input_count; ++index) {
        const int64_t x = values[2 * index], y = values[2 * index + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        points[index] = (point_t){x, y, index};
    }
    if (input_count == 0) return 0;
    sort_points(points, scratch, 0, input_count);
    size_t count = 0;
    for (size_t index = 0; index < input_count; ++index) {
        if (count == 0 || points[count - 1].x != points[index].x || points[count - 1].y != points[index].y)
            points[count++] = points[index];
    }

    bool on_hull[MAX_POINTS] = {false};
    if (count == 1) on_hull[0] = true;
    else {
        on_hull[0] = true;
        on_hull[count - 1] = true;
        quick_hull(points, count, 0, count - 1, on_hull);
        quick_hull(points, count, count - 1, 0, on_hull);
    }
    size_t hull_count = 0;
    for (size_t index = 0; index < count; ++index) if (on_hull[index]) ++hull_count;
    if (output == NULL || output_capacity < 4 * hull_count) return -2;
    size_t position = 0;
    for (size_t index = 0; index < count; ++index) {
        if (!on_hull[index]) continue;
        const uint32_t id = (uint32_t)points[index].id;
        for (size_t byte = 0; byte < 4; ++byte)
            output[4 * position + byte] = (uint8_t)(id >> (8 * byte));
        ++position;
    }
    return (int64_t)hull_count;
}
