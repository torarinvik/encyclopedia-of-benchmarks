/* Integer Bresenham rasterization with both endpoints included. */
#include <stddef.h>
#include <stdint.h>

#define COORDINATE_LIMIT INT64_C(1000000)
#define MAX_STEPS INT64_C(4096)

static void write_i32_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bresenhams_line(const int64_t *values, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 4) return -1;
    for (size_t index = 0; index < 4; ++index)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;

    int64_t x = values[0], y = values[1];
    const int64_t end_x = values[2], end_y = values[3];
    const int64_t delta_x = end_x >= x ? end_x - x : x - end_x;
    const int64_t delta_y = end_y >= y ? end_y - y : y - end_y;
    const int64_t steps = delta_x > delta_y ? delta_x : delta_y;
    if (steps > MAX_STEPS) return -1;
    const size_t point_count = (size_t)steps + 1;
    const size_t output_bytes = point_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    const int64_t sx = x < end_x ? 1 : -1;
    const int64_t sy = y < end_y ? 1 : -1;
    int64_t error = delta_x - delta_y;
    size_t position = 0;
    for (;;) {
        write_i32_le(output, position, x);
        write_i32_le(output, position + 4, y);
        position += 8;
        if (x == end_x && y == end_y) break;
        const int64_t doubled_error = 2 * error;
        if (doubled_error >= -delta_y) {
            error -= delta_y;
            x += sx;
        }
        if (doubled_error <= delta_x) {
            error += delta_x;
            y += sy;
        }
    }
    return (int64_t)output_bytes;
}
