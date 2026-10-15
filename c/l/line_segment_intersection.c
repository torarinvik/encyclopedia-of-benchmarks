/* Closed-segment intersection using exact integer orientations. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define COORDINATE_LIMIT 10000

typedef struct { int64_t x, y; } point_t;

static int64_t orientation(point_t a, point_t b, point_t c)
{
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

static bool on_segment(point_t a, point_t b, point_t point)
{
    return point.x >= (a.x < b.x ? a.x : b.x) && point.x <= (a.x > b.x ? a.x : b.x) &&
        point.y >= (a.y < b.y ? a.y : b.y) && point.y <= (a.y > b.y ? a.y : b.y);
}

int64_t line_segment_intersection(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    (void)output;
    (void)output_capacity;
    if (values == NULL || length != 8) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;

    const point_t a = {values[0], values[1]};
    const point_t b = {values[2], values[3]};
    const point_t c = {values[4], values[5]};
    const point_t d = {values[6], values[7]};
    const int64_t ab_c = orientation(a, b, c);
    const int64_t ab_d = orientation(a, b, d);
    const int64_t cd_a = orientation(c, d, a);
    const int64_t cd_b = orientation(c, d, b);
    const bool proper_crossing = ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
        ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0));
    const bool touches_or_overlaps =
        (ab_c == 0 && on_segment(a, b, c)) || (ab_d == 0 && on_segment(a, b, d)) ||
        (cd_a == 0 && on_segment(c, d, a)) || (cd_b == 0 && on_segment(c, d, b));
    return proper_crossing || touches_or_overlaps ? 1 : 0;
}
