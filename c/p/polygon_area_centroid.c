#include <stddef.h>
#include <stdint.h>

#define MIN_VERTICES 3
#define MAX_VERTICES 16
#define MIN_COORDINATE (-50)
#define MAX_COORDINATE 50
#define MAX_PARSEABLE_LENGTH 34
#define OUTPUT_BYTES 16
#define OUTPUT_SCALE INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t rounded_micro(int64_t numerator, int64_t denominator)
{
    if (denominator < 0) {
        numerator = -numerator;
        denominator = -denominator;
    }
    const int64_t sign = numerator < 0 ? -1 : 1;
    const uint64_t magnitude = (uint64_t)(numerator < 0 ? -numerator : numerator);
    const uint64_t scaled = magnitude * (uint64_t)OUTPUT_SCALE;
    uint64_t quotient = scaled / (uint64_t)denominator;
    const uint64_t remainder = scaled % (uint64_t)denominator;
    if (2 * remainder >= (uint64_t)denominator) ++quotient;
    return sign * (int64_t)quotient;
}

int64_t polygon_area_centroid(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 7 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < MIN_VERTICES || count_value > MAX_VERTICES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;

    int64_t xs[MAX_VERTICES];
    int64_t ys[MAX_VERTICES];
    for (size_t i = 0; i < count; ++i) {
        const int64_t x = input[1 + 2 * i];
        const int64_t y = input[2 + 2 * i];
        if (x < MIN_COORDINATE || x > MAX_COORDINATE ||
            y < MIN_COORDINATE || y > MAX_COORDINATE) return -1;
        for (size_t j = 0; j < i; ++j)
            if (xs[j] == x && ys[j] == y) return -1;
        xs[i] = x;
        ys[i] = y;
    }

    int64_t twice_area = 0;
    for (size_t i = 0; i < count; ++i) {
        const size_t next = (i + 1) % count;
        twice_area += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if (twice_area == 0) return -1;
    const int64_t orientation = twice_area > 0 ? 1 : -1;
    for (size_t i = 0; i < count; ++i) {
        const size_t next = (i + 1) % count;
        for (size_t j = 0; j < count; ++j) {
            if (j == i || j == next) continue;
            const int64_t side = (xs[next] - xs[i]) * (ys[j] - ys[i]) -
                                 (ys[next] - ys[i]) * (xs[j] - xs[i]);
            if (side * orientation <= 0) return -1;
        }
    }

    int64_t numerator_x = 0;
    int64_t numerator_y = 0;
    for (size_t i = 0; i < count; ++i) {
        const size_t next = (i + 1) % count;
        const int64_t cross = xs[i] * ys[next] - xs[next] * ys[i];
        numerator_x += (xs[i] + xs[next]) * cross;
        numerator_y += (ys[i] + ys[next]) * cross;
    }
    const int64_t x_micro = rounded_micro(numerator_x, 3 * twice_area);
    const int64_t y_micro = rounded_micro(numerator_y, 3 * twice_area);

    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    store_i64_le(output, 0, x_micro);
    store_i64_le(output, 8, y_micro);
    return OUTPUT_BYTES;
}
