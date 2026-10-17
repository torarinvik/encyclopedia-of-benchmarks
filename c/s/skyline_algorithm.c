#include <stddef.h>
#include <stdint.h>

#define MAX_POINT_COUNT 64u
#define MAX_PARSEABLE_INPUT_VALUES 130u
#define MAX_OUTPUT_BYTES 513u

typedef struct {
    int32_t x;
    int32_t y;
} Point;

static int dominates(Point left, Point right)
{
    return (left.x < right.x && left.y <= right.y) ||
           (left.x <= right.x && left.y < right.y);
}

static size_t produce_skyline(const Point *points, size_t count, Point *output)
{
    if (count == 1u) {
        output[0] = points[0];
        return 1u;
    }
    if (count == 2u) {
        if (dominates(points[0], points[1])) {
            output[0] = points[0];
            return 1u;
        }
        if (dominates(points[1], points[0])) {
            output[0] = points[1];
            return 1u;
        }
        output[0] = points[0];
        output[1] = points[1];
        return 2u;
    }

    const size_t middle = count / 2u;
    Point left[MAX_POINT_COUNT];
    Point right[MAX_POINT_COUNT];
    size_t left_count = produce_skyline(points, middle, left);
    size_t right_count = produce_skyline(points + middle, count - middle, right);

    /* Match the source's adjacent same-x cleanup of the left frontier. */
    size_t index = 0u;
    while (index + 1u < left_count) {
        if (left[index].x == left[index + 1u].x && left[index].y > left[index + 1u].y) {
            for (size_t move = index; move + 1u < left_count; ++move) {
                left[move] = left[move + 1u];
            }
            --left_count;
            if (index > 0u) --index;
        } else {
            ++index;
        }
    }

    int32_t minimum_y = left[0].y;
    for (index = 1u; index < left_count; ++index) {
        if (minimum_y > left[index].y) {
            minimum_y = left[index].y;
            if (minimum_y == 1) break;
        }
    }

    index = 0u;
    while (index < right_count) {
        if (right[index].y >= minimum_y) {
            for (size_t move = index; move + 1u < right_count; ++move) {
                right[move] = right[move + 1u];
            }
            --right_count;
        } else {
            ++index;
        }
    }

    for (index = 0u; index < left_count; ++index) output[index] = left[index];
    for (size_t right_index = 0u; right_index < right_count; ++right_index) {
        output[left_count + right_index] = right[right_index];
    }
    return left_count + right_count;
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8u);
    output[offset + 2u] = (uint8_t)(bits >> 16u);
    output[offset + 3u] = (uint8_t)(bits >> 24u);
}

int64_t skyline_algorithm(const int64_t *input, size_t input_length,
                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3u ||
        input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;

    if (input[0] < 1 || input[0] > (int64_t)MAX_POINT_COUNT) return -1;
    const size_t point_count = (size_t)input[0];
    if (input_length != 1u + 2u * point_count) return -1;

    Point points[MAX_POINT_COUNT];
    for (size_t index = 0u; index < point_count; ++index) {
        const int64_t x = input[1u + 2u * index];
        const int64_t y = input[2u + 2u * index];
        if (x < INT32_MIN || x > INT32_MAX || y < 1 || y > INT32_MAX) return -1;
        if (index > 0u && x <= input[1u + 2u * (index - 1u)]) return -1;
        points[index].x = (int32_t)x;
        points[index].y = (int32_t)y;
    }

    Point skyline[MAX_POINT_COUNT];
    const size_t skyline_count = produce_skyline(points, point_count, skyline);
    uint8_t staged[MAX_OUTPUT_BYTES] = {0u};
    staged[0] = (uint8_t)skyline_count;
    for (size_t index = 0u; index < skyline_count; ++index) {
        const size_t offset = 1u + 8u * index;
        write_i32_le(staged, offset, skyline[index].x);
        write_i32_le(staged, offset + 4u, skyline[index].y);
    }

    const size_t output_length = 1u + 8u * skyline_count;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0u; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
