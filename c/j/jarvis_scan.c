/* Return an integer Jarvis-scan hull in counter-clockwise order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 64
#define MIN_COORDINATE (-10000)
#define MAX_COORDINATE 10000

static int64_t orientation(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                           int64_t cx, int64_t cy)
{
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t jarvis_scan(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_POINTS) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + 2 * count) return -1;

    int64_t x[MAX_POINTS], y[MAX_POINTS];
    for (size_t point = 0; point < count; ++point) {
        x[point] = input[1 + 2 * point];
        y[point] = input[2 + 2 * point];
        if (x[point] < MIN_COORDINATE || x[point] > MAX_COORDINATE ||
            y[point] < MIN_COORDINATE || y[point] > MAX_COORDINATE) return -1;
    }
    if (count <= 2) return 0;
    for (size_t first = 0; first < count; ++first) {
        for (size_t second = first + 1; second < count; ++second) {
            if (x[first] == x[second] && y[first] == y[second]) return -1;
        }
    }
    for (size_t first = 0; first + 2 < count; ++first) {
        for (size_t second = first + 1; second + 1 < count; ++second) {
            for (size_t third = second + 1; third < count; ++third) {
                if (orientation(x[first], y[first], x[second], y[second],
                                x[third], y[third]) == 0) return -1;
            }
        }
    }

    size_t start = 0;
    for (size_t point = 1; point < count; ++point) {
        if (x[point] < x[start] || (x[point] == x[start] && y[point] < y[start])) start = point;
    }
    size_t hull[MAX_POINTS], hull_count = 0, current = start;
    for (;;) {
        if (hull_count == count) return -1;
        hull[hull_count++] = current;
        size_t candidate = (current + 1) % count;
        for (size_t point = 0; point < count; ++point) {
            if (orientation(x[current], y[current], x[point], y[point],
                            x[candidate], y[candidate]) > 0) candidate = point;
        }
        if (candidate == start) break;
        current = candidate;
    }
    const size_t bytes = hull_count * 16;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t index = 0; index < hull_count; ++index) {
        put_i64(output, index * 16, x[hull[index]]);
        put_i64(output, index * 16 + 8, y[hull[index]]);
    }
    return (int64_t)bytes;
}
