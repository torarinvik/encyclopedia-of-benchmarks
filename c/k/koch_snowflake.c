#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 29
#define MAX_INPUT_LENGTH 20
#define MAX_COORDINATE 1000.0

typedef struct { float x, y; } point32;

static float rotate_add(float a, float b) { return a + b; }
static float rotate_sub(float a, float b) { return a - b; }
static float rotate_mul(float a, float b) { return a * b; }
static float rotate_div(float a, float b) { return a / b; }

int64_t koch_snowflake(const double *input, size_t length,
                       double *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const double steps_value = input[0];
    const double count_value = input[1];
    if (!isfinite(steps_value) || floor(steps_value) != steps_value ||
        steps_value < 0.0 || steps_value > 1.0 ||
        !isfinite(count_value) || floor(count_value) != count_value ||
        count_value < 2.0 || count_value > 8.0) return -1;
    const size_t steps = (size_t)steps_value;
    const size_t point_count = (size_t)count_value;
    if (length != 2 + 2 * point_count) return -1;
    for (size_t i = 0; i < 2 * point_count; ++i)
        if (!isfinite(input[i + 2]) || fabs(input[i + 2]) > MAX_COORDINATE) return -1;

    const size_t result_points = steps == 0 ? point_count : 4 * (point_count - 1) + 1;
    const size_t result_count = 2 * result_points;
    if (output == NULL || output_capacity < result_count) return -2;

    point32 first[MAX_POINTS], second[MAX_POINTS];
    for (size_t i = 0; i < point_count; ++i) {
        first[i].x = (float)input[2 + 2 * i];
        first[i].y = (float)input[3 + 2 * i];
    }
    point32 *source = first, *destination = second;
    size_t source_count = point_count;
    const float two = 2.0f;
    const float cosine = 0.49999997f, sine = 0.86602545f;
    for (size_t step = 0; step < steps; ++step) {
        size_t cursor = 0;
        for (size_t i = 0; i + 1 < source_count; ++i) {
            const point32 start = source[i], end = source[i + 1];
            const float dx = rotate_sub(end.x, start.x);
            const float dy = rotate_sub(end.y, start.y);
            const float tx = rotate_div(dx, 3.0f);
            const float ty = rotate_div(dy, 3.0f);
            const float first_x = rotate_add(start.x, tx);
            const float first_y = rotate_add(start.y, ty);
            const float rx = rotate_sub(rotate_mul(cosine, tx), rotate_mul(sine, ty));
            const float ry = rotate_add(rotate_mul(sine, tx), rotate_mul(cosine, ty));
            const float peak_x = rotate_add(first_x, rx);
            const float peak_y = rotate_add(first_y, ry);
            const float tx2 = rotate_div(rotate_mul(dx, two), 3.0f);
            const float ty2 = rotate_div(rotate_mul(dy, two), 3.0f);
            destination[cursor++] = start;
            destination[cursor++] = (point32){first_x, first_y};
            destination[cursor++] = (point32){peak_x, peak_y};
            destination[cursor++] = (point32){rotate_add(start.x, tx2), rotate_add(start.y, ty2)};
        }
        destination[cursor++] = source[source_count - 1];
        source_count = cursor;
        point32 *swap = source; source = destination; destination = swap;
    }
    for (size_t i = 0; i < result_points; ++i) {
        output[2 * i] = (double)source[i].x;
        output[2 * i + 1] = (double)source[i].y;
    }
    return (int64_t)result_count;
}
