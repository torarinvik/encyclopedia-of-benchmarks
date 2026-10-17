#include <stddef.h>
#include <stdint.h>

#define MAX_POINT_COUNT 64
#define MAX_PARSEABLE_INPUT_LENGTH 130
#define MAX_COORDINATE 1000000

typedef struct { int32_t x; int32_t y; } Point;

static int point_less(Point a, Point b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

static int64_t cross(Point origin, Point first, Point second) {
    const int64_t dx1 = (int64_t)first.x - origin.x;
    const int64_t dy1 = (int64_t)first.y - origin.y;
    const int64_t dx2 = (int64_t)second.x - origin.x;
    const int64_t dy2 = (int64_t)second.y - origin.y;
    return dx1 * dy2 - dy1 * dx2;
}

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t monotone_chain(const int64_t *values, size_t length,
                       uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_POINT_COUNT) return -1;
    const size_t count = (size_t)raw_count;
    if (length != 1 + 2 * count) return -1;

    Point points[MAX_POINT_COUNT];
    Point scratch[MAX_POINT_COUNT];
    Point hull[2 * MAX_POINT_COUNT];
    for (size_t index = 0; index < count; ++index) {
        const int64_t x = values[1 + 2 * index];
        const int64_t y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE ||
            y < -MAX_COORDINATE || y > MAX_COORDINATE) return -1;
        points[index].x = (int32_t)x;
        points[index].y = (int32_t)y;
    }

    for (size_t width = 1; width < count; width *= 2) {
        for (size_t start = 0; start < count; start += 2 * width) {
            size_t middle = start + width;
            if (middle > count) middle = count;
            size_t end = middle + width;
            if (end > count) end = count;
            size_t left = start, right = middle, destination = start;
            while (left < middle && right < end)
                scratch[destination++] = point_less(points[right], points[left]) ? points[right++] : points[left++];
            while (left < middle) scratch[destination++] = points[left++];
            while (right < end) scratch[destination++] = points[right++];
        }
        for (size_t index = 0; index < count; ++index) points[index] = scratch[index];
    }

    size_t unique_count = 0;
    for (size_t index = 0; index < count; ++index) {
        if (unique_count == 0 || points[index].x != points[unique_count - 1].x ||
            points[index].y != points[unique_count - 1].y)
            points[unique_count++] = points[index];
    }

    size_t hull_count = 0;
    if (unique_count == 1) {
        hull[hull_count++] = points[0];
    } else if (unique_count > 1) {
        for (size_t index = 0; index < unique_count; ++index) {
            while (hull_count >= 2 &&
                   cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                --hull_count;
            hull[hull_count++] = points[index];
        }
        const size_t lower_count = hull_count;
        for (size_t index = unique_count - 1; index > 0;) {
            --index;
            while (hull_count > lower_count &&
                   cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                --hull_count;
            hull[hull_count++] = points[index];
        }
        --hull_count;
    }

    const size_t byte_count = 8 * hull_count;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t index = 0; index < hull_count; ++index) {
        store_i32_le(output, 8 * index, hull[index].x);
        store_i32_le(output, 8 * index + 4, hull[index].y);
    }
    return (int64_t)byte_count;
}
