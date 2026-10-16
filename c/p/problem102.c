/* Count triangles whose strict interior contains the origin. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES ((size_t)6000)
#define MIN_COORD INT64_C(-1000)
#define MAX_COORD INT64_C(1000)

static int64_t origin_inside(int64_t x1, int64_t y1, int64_t x2, int64_t y2,
                             int64_t x3, int64_t y3)
{
    const int64_t abx = x2 - x1, aby = y2 - y1;
    const int64_t acx = x3 - x1, acy = y3 - y1;
    int64_t denominator = acx * aby - acy * abx;
    int64_t numerator_a = -(x1 * aby - y1 * abx);
    int64_t numerator_b = x1 * acy - y1 * acx;
    if (denominator == 0) return -1;
    if (denominator < 0) {
        denominator = -denominator;
        numerator_a = -numerator_a;
        numerator_b = -numerator_b;
    }
    return numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator;
}

int64_t problem102(const int64_t *input, size_t length)
{
    if (input == NULL || length < 6 || length > MAX_VALUES || length % 6 != 0) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < MIN_COORD || input[index] > MAX_COORD) return -1;
    int64_t count = 0;
    for (size_t offset = 0; offset < length; offset += 6) {
        const int64_t inside = origin_inside(input[offset], input[offset + 1], input[offset + 2],
                                             input[offset + 3], input[offset + 4], input[offset + 5]);
        if (inside < 0) return -1;
        count += inside;
    }
    return count;
}
