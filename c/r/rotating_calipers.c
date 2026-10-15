#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 1024
#define MAX_COORDINATE INT64_C(1000000000)
#define INVALID_RESULT (-1.0e300)

typedef struct {
    int64_t x;
    int64_t y;
} point_t;

static int before_xy(point_t left, point_t right)
{
    return left.x < right.x || (left.x == right.x && left.y < right.y);
}

static void merge_sort(point_t *points, point_t *scratch, size_t begin, size_t end)
{
    if (end - begin < 2) return;
    const size_t middle = begin + (end - begin) / 2;
    merge_sort(points, scratch, begin, middle);
    merge_sort(points, scratch, middle, end);
    size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end)
        scratch[out++] = before_xy(points[right], points[left]) ? points[right++] : points[left++];
    while (left < middle) scratch[out++] = points[left++];
    while (right < end) scratch[out++] = points[right++];
    for (size_t index = begin; index < end; ++index) points[index] = scratch[index];
}

static int64_t cross(point_t origin, point_t a, point_t b)
{
    return (a.x - origin.x) * (b.y - origin.y) -
           (a.y - origin.y) * (b.x - origin.x);
}

static uint64_t distance_squared(point_t a, point_t b)
{
    const int64_t dx = a.x - b.x;
    const int64_t dy = a.y - b.y;
    return (uint64_t)(dx * dx) + (uint64_t)(dy * dy);
}

double rotating_calipers(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5 || length > 2 * MAX_POINTS + 1 || length % 2 == 0)
        return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 2 || count_value > MAX_POINTS || length != 1 + 2 * (size_t)count_value)
        return INVALID_RESULT;

    const size_t count = (size_t)count_value;
    point_t points[MAX_POINTS], scratch[MAX_POINTS], lower[MAX_POINTS], upper[MAX_POINTS];
    for (size_t index = 0; index < count; ++index) {
        const int64_t x = values[1 + 2 * index], y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE ||
            y < -MAX_COORDINATE || y > MAX_COORDINATE) return INVALID_RESULT;
        points[index] = (point_t){x, y};
    }

    merge_sort(points, scratch, 0, count);
    size_t unique_count = 0;
    for (size_t index = 0; index < count; ++index) {
        if (unique_count == 0 || points[index].x != points[unique_count - 1].x ||
            points[index].y != points[unique_count - 1].y)
            points[unique_count++] = points[index];
    }
    if (unique_count == 1) return 0.0;

    size_t lower_size = 0;
    for (size_t index = 0; index < unique_count; ++index) {
        while (lower_size >= 2 && cross(lower[lower_size - 2], lower[lower_size - 1], points[index]) <= 0)
            --lower_size;
        lower[lower_size++] = points[index];
    }
    size_t upper_size = 0;
    for (size_t index = unique_count; index-- > 0;) {
        while (upper_size >= 2 && cross(upper[upper_size - 2], upper[upper_size - 1], points[index]) <= 0)
            --upper_size;
        upper[upper_size++] = points[index];
    }
    point_t hull[2 * MAX_POINTS];
    size_t hull_size = 0;
    for (size_t index = 0; index + 1 < lower_size; ++index) hull[hull_size++] = lower[index];
    for (size_t index = 0; index + 1 < upper_size; ++index) hull[hull_size++] = upper[index];
    if (hull_size == 2)
        return sqrt((double)distance_squared(hull[0], hull[1]));

    size_t antipodal = 1;
    size_t advances = 0;
    while (advances < hull_size &&
           cross(hull[0], hull[1], hull[(antipodal + 1) % hull_size]) >
           cross(hull[0], hull[1], hull[antipodal])) {
        antipodal = (antipodal + 1) % hull_size;
        ++advances;
    }

    uint64_t maximum_squared = 0;
    for (size_t current = 0; current < hull_size; ++current) {
        const size_t next = (current + 1) % hull_size;
        advances = 0;
        while (advances < hull_size &&
               cross(hull[current], hull[next], hull[(antipodal + 1) % hull_size]) >
               cross(hull[current], hull[next], hull[antipodal])) {
            antipodal = (antipodal + 1) % hull_size;
            ++advances;
        }
        const size_t after_antipodal = (antipodal + 1) % hull_size;
        const uint64_t candidates[] = {
            distance_squared(hull[current], hull[antipodal]),
            distance_squared(hull[next], hull[antipodal]),
            distance_squared(hull[current], hull[after_antipodal]),
            distance_squared(hull[next], hull[after_antipodal]),
        };
        for (size_t index = 0; index < 4; ++index)
            if (candidates[index] > maximum_squared) maximum_squared = candidates[index];
    }
    return sqrt((double)maximum_squared);
}
