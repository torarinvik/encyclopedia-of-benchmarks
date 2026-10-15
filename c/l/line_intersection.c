/* Unique intersection point of two lines or closed segments. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define COORDINATE_LIMIT 10000

typedef struct { int64_t x, y; } point_t;

static int64_t cross(point_t a, point_t b, point_t c)
{
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

static bool same_point(point_t a, point_t b)
{
    return a.x == b.x && a.y == b.y;
}

static bool on_segment(point_t a, point_t b, point_t p)
{
    return cross(a, b, p) == 0 && p.x >= (a.x < b.x ? a.x : b.x) &&
        p.x <= (a.x > b.x ? a.x : b.x) && p.y >= (a.y < b.y ? a.y : b.y) &&
        p.y <= (a.y > b.y ? a.y : b.y);
}

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int64_t write_point(uint8_t *output, size_t capacity, double x, double y)
{
    if (output == NULL || capacity < 16) return -2;
    write_f64_le(output, 0, x);
    write_f64_le(output, 8, y);
    return 1;
}

int64_t line_intersection(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (length != 9 || values == NULL || (values[8] != 0 && values[8] != 1)) return -1;
    point_t p1 = {values[0], values[1]}, p2 = {values[2], values[3]};
    point_t q1 = {values[4], values[5]}, q2 = {values[6], values[7]};
    for (size_t index = 0; index < 8; ++index)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;
    const bool as_segments = values[8] == 1;
    const bool p_is_point = same_point(p1, p2), q_is_point = same_point(q1, q2);
    if (!as_segments && (p_is_point || q_is_point)) return -1;
    if (as_segments && p_is_point && q_is_point)
        return same_point(p1, q1) ? write_point(output, output_capacity, (double)p1.x, (double)p1.y) : 0;
    if (as_segments && p_is_point)
        return on_segment(q1, q2, p1) ? write_point(output, output_capacity, (double)p1.x, (double)p1.y) : 0;
    if (as_segments && q_is_point)
        return on_segment(p1, p2, q1) ? write_point(output, output_capacity, (double)q1.x, (double)q1.y) : 0;

    const int64_t denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x);
    if (denominator == 0) return 0;
    const int64_t determinant_p = p1.x * p2.y - p1.y * p2.x;
    const int64_t determinant_q = q1.x * q2.y - q1.y * q2.x;
    const int64_t numerator_x = determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q;
    const int64_t numerator_y = determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q;
    if (as_segments) {
        const int64_t positive_denominator = denominator < 0 ? -denominator : denominator;
        const int64_t positive_x = denominator < 0 ? -numerator_x : numerator_x;
        const int64_t positive_y = denominator < 0 ? -numerator_y : numerator_y;
        const int64_t p_min_x = p1.x < p2.x ? p1.x : p2.x;
        const int64_t p_max_x = p1.x > p2.x ? p1.x : p2.x;
        const int64_t q_min_x = q1.x < q2.x ? q1.x : q2.x;
        const int64_t q_max_x = q1.x > q2.x ? q1.x : q2.x;
        const int64_t p_min_y = p1.y < p2.y ? p1.y : p2.y;
        const int64_t p_max_y = p1.y > p2.y ? p1.y : p2.y;
        const int64_t q_min_y = q1.y < q2.y ? q1.y : q2.y;
        const int64_t q_max_y = q1.y > q2.y ? q1.y : q2.y;
        const int64_t min_x = p_min_x > q_min_x ? p_min_x : q_min_x;
        const int64_t max_x = p_max_x < q_max_x ? p_max_x : q_max_x;
        const int64_t min_y = p_min_y > q_min_y ? p_min_y : q_min_y;
        const int64_t max_y = p_max_y < q_max_y ? p_max_y : q_max_y;
        if (positive_x < min_x * positive_denominator || positive_x > max_x * positive_denominator ||
            positive_y < min_y * positive_denominator || positive_y > max_y * positive_denominator) return 0;
        return write_point(output, output_capacity,
                           (double)positive_x / (double)positive_denominator,
                           (double)positive_y / (double)positive_denominator);
    }
    return write_point(output, output_capacity, (double)numerator_x / (double)denominator,
                       (double)numerator_y / (double)denominator);
}
