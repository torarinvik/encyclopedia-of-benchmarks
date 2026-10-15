/* Preserve the Java midpoint-circle routine's octant order and duplicate points. */
#include <stddef.h>
#include <stdint.h>

#define MAX_RADIUS 1000

static void append_i32_le(uint8_t *output, size_t position, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[4 * position + byte] = (uint8_t)(bits >> (8 * byte));
}

static void append_point(uint8_t *output, size_t index, int64_t x, int64_t y)
{
    append_i32_le(output, 2 * index, x);
    append_i32_le(output, 2 * index + 1, y);
}

static void append_symmetric_points(uint8_t *output, size_t *count,
                                    int64_t center_x, int64_t center_y,
                                    int64_t x, int64_t y)
{
    append_point(output, (*count)++, center_x + x, center_y + y);
    append_point(output, (*count)++, center_x - x, center_y + y);
    append_point(output, (*count)++, center_x + x, center_y - y);
    append_point(output, (*count)++, center_x - x, center_y - y);
    append_point(output, (*count)++, center_x + y, center_y + x);
    append_point(output, (*count)++, center_x - y, center_y + x);
    append_point(output, (*count)++, center_x + y, center_y - x);
    append_point(output, (*count)++, center_x - y, center_y - x);
}

static size_t point_count(int64_t radius)
{
    if (radius == 0) return 1;
    int64_t x = radius, y = 0, decision = 1 - radius;
    size_t groups = 1;
    while (x > y) {
        ++y;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            --x;
            decision += 2 * y - 2 * x + 1;
        }
        ++groups;
    }
    return groups * 8;
}

int64_t midpoint_circle(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 3 || values[0] < -10000 || values[0] > 10000 ||
        values[1] < -10000 || values[1] > 10000 || values[2] < 0 || values[2] > MAX_RADIUS) return -1;
    const size_t count = point_count(values[2]);
    if (output == NULL || output_capacity < count * 8) return -2;
    if (values[2] == 0) {
        append_point(output, 0, values[0], values[1]);
        return 1;
    }

    int64_t x = values[2], y = 0, decision = 1 - values[2];
    size_t written = 0;
    append_symmetric_points(output, &written, values[0], values[1], x, y);
    while (x > y) {
        ++y;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            --x;
            decision += 2 * y - 2 * x + 1;
        }
        append_symmetric_points(output, &written, values[0], values[1], x, y);
    }
    return (int64_t)written;
}
