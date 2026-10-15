/* Two-region midpoint ellipse rasterization with the Java source's point order. */
#include <stddef.h>
#include <stdint.h>

static void write_i32_le(uint8_t *output, size_t position, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[position * 4 + byte] = (uint8_t)(bits >> (8 * byte));
}

static void emit_point(uint8_t *output, size_t *count, int64_t x, int64_t y)
{
    if (output != NULL) {
        write_i32_le(output, 2 * *count, x);
        write_i32_le(output, 2 * *count + 1, y);
    }
    ++*count;
}

static void emit_symmetric(uint8_t *output, size_t *count,
                           int64_t center_x, int64_t center_y, int64_t x, int64_t y)
{
    emit_point(output, count, center_x + x, center_y + y);
    emit_point(output, count, center_x - x, center_y + y);
    emit_point(output, count, center_x + x, center_y - y);
    emit_point(output, count, center_x - x, center_y - y);
}

static size_t rasterize(uint8_t *output, int64_t center_x, int64_t center_y,
                        int64_t a, int64_t b)
{
    size_t count = 0;
    if (a == 0 && b == 0) {
        emit_point(output, &count, center_x, center_y);
        return count;
    }
    if (a == 0) {
        for (int64_t y = center_y - b; y <= center_y + b; ++y)
            emit_point(output, &count, center_x, y);
        return count;
    }
    if (b == 0) {
        for (int64_t x = center_x - a; x <= center_x + a; ++x)
            emit_point(output, &count, x, center_y);
        return count;
    }

    int64_t x = 0, y = b;
    const int64_t a_squared = a * a, b_squared = b * b;
    double d1 = (double)b_squared - (double)(a_squared * b) + 0.25 * (double)a_squared;
    double dx = 2.0 * (double)b_squared * (double)x;
    double dy = 2.0 * (double)a_squared * (double)y;
    while (dx < dy) {
        emit_symmetric(output, &count, center_x, center_y, x, y);
        if (d1 < 0.0) {
            ++x;
            dx += 2.0 * (double)b_squared;
            d1 += dx + (double)b_squared;
        } else {
            ++x;
            --y;
            dx += 2.0 * (double)b_squared;
            dy -= 2.0 * (double)a_squared;
            d1 += dx - dy + (double)b_squared;
        }
    }

    double d2 = (double)b_squared * ((double)x + 0.5) * ((double)x + 0.5) +
        (double)(a_squared * (y - 1) * (y - 1)) - (double)(a_squared * b_squared);
    while (y >= 0) {
        emit_symmetric(output, &count, center_x, center_y, x, y);
        if (d2 > 0.0) {
            --y;
            dy -= 2.0 * (double)a_squared;
            d2 += (double)a_squared - dy;
        } else {
            --y;
            ++x;
            dx += 2.0 * (double)b_squared;
            dy -= 2.0 * (double)a_squared;
            d2 += dx - dy + (double)a_squared;
        }
    }
    return count;
}

int64_t midpoint_ellipse(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 4 || values[0] < -10000 || values[0] > 10000 ||
        values[1] < -10000 || values[1] > 10000 || values[2] < 0 || values[2] > 100 ||
        values[3] < 0 || values[3] > 100) return -1;
    const size_t count = rasterize(NULL, values[0], values[1], values[2], values[3]);
    if (output == NULL || output_capacity < count * 8) return -2;
    rasterize(output, values[0], values[1], values[2], values[3]);
    return (int64_t)count;
}
