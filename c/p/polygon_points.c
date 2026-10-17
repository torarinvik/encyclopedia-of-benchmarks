#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH ((size_t)66)
#define MAX_VERTICES INT64_C(32)
#define INVALID_RESULT INT64_C(-1)

static int64_t abs_i64(int64_t value)
{
    return value < 0 ? -value : value;
}

static int64_t gcd_i64(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

static int64_t cross(int64_t x1, int64_t y1, int64_t x2, int64_t y2)
{
    return x1 * y2 - x2 * y1;
}

int64_t polygon_points(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t raw_n = values[0];
    if (raw_n < 3 || raw_n > MAX_VERTICES || length != 1 + 2 * (size_t)raw_n) return INVALID_RESULT;
    const size_t n = (size_t)raw_n;
    for (size_t i = 0; i < 2 * n; ++i) {
        if (values[1 + i] < -1000 || values[1 + i] > 1000) return INVALID_RESULT;
    }

    const int64_t origin_x = values[1], origin_y = values[2];
    int64_t doubled_area = 0;
    for (size_t i = 2; i < n; ++i) {
        const int64_t x1 = values[1 + 2 * i] - origin_x;
        const int64_t y1 = values[2 + 2 * i] - origin_y;
        const int64_t x2 = values[1 + 2 * (i - 1)] - origin_x;
        const int64_t y2 = values[2 + 2 * (i - 1)] - origin_y;
        doubled_area += cross(x1, y1, x2, y2);
    }
    const int64_t area = abs_i64(doubled_area / 2);

    int64_t boundary = raw_n;
    for (size_t i = 0; i < n; ++i) {
        const size_t next = (i + 1) % n;
        const int64_t dx = values[1 + 2 * i] - values[1 + 2 * next];
        const int64_t dy = values[2 + 2 * i] - values[2 + 2 * next];
        boundary += abs_i64(gcd_i64(dx, dy)) - 1;
    }
    return area + 1 - boundary / 2;
}
