#include <stddef.h>
#include <stdint.h>

enum { MAX_DIMENSION = 8, MAX_CELLS = 64, MAX_INPUT_LENGTH = 79 };

typedef struct { int64_t first, second, translation; } AxisSolution;

static int solve_axis(const int64_t x[3], const int64_t y[3], const int64_t target[3],
                      AxisSolution *solution) {
    const int64_t determinant = x[0] * (y[1] - y[2])
        + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1]);
    if (determinant == 0) return 0;
    const int64_t first_numerator = target[0] * (y[1] - y[2])
        + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1]);
    const int64_t second_numerator = x[0] * (target[1] - target[2])
        + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1]);
    const int64_t translation_numerator = x[0] * (y[1] * target[2] - y[2] * target[1])
        + x[1] * (y[2] * target[0] - y[0] * target[2])
        + x[2] * (y[0] * target[1] - y[1] * target[0]);
    if (first_numerator % determinant != 0 || second_numerator % determinant != 0 ||
        translation_numerator % determinant != 0) return 0;
    solution->first = first_numerator / determinant;
    solution->second = second_numerator / determinant;
    solution->translation = translation_numerator / determinant;
    return 1;
}

int64_t affine_image_rotation(const int32_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || cols_value < 1 || cols_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value, cols = (size_t)cols_value;
    const size_t cells = rows * cols;
    if (length != 14 + cells) return -1;

    uint8_t pixels[MAX_CELLS];
    for (size_t i = 0; i < cells; ++i) {
        const int32_t value = input[2 + i];
        if (value < 0 || value > 255) return -1;
        pixels[i] = (uint8_t)value;
    }

    const size_t point_offset = 2 + cells;
    int64_t source_x[3], source_y[3], destination_x[3], destination_y[3];
    for (size_t i = 0; i < 3; ++i) {
        source_x[i] = input[point_offset + 2 * i];
        source_y[i] = input[point_offset + 2 * i + 1];
        destination_x[i] = input[point_offset + 6 + 2 * i];
        destination_y[i] = input[point_offset + 7 + 2 * i];
        if (source_x[i] < -16 || source_x[i] > 16 || source_y[i] < -16 || source_y[i] > 16 ||
            destination_x[i] < -16 || destination_x[i] > 16 ||
            destination_y[i] < -16 || destination_y[i] > 16) return -1;
    }

    AxisSolution x_axis, y_axis;
    if (!solve_axis(source_x, source_y, destination_x, &x_axis) ||
        !solve_axis(source_x, source_y, destination_y, &y_axis)) return -1;
    const int64_t a = x_axis.first, b = x_axis.second, tx = x_axis.translation;
    const int64_t c = y_axis.first, d = y_axis.second, ty = y_axis.translation;
    if (a < -2 || a > 2 || b < -2 || b > 2 || c < -2 || c > 2 || d < -2 || d > 2 ||
        tx < -16 || tx > 16 || ty < -16 || ty > 16) return -1;
    const int64_t determinant = a * d - b * c;
    if (determinant != -1 && determinant != 1) return -1;
    for (size_t i = 0; i < 3; ++i) {
        if (destination_x[i] != a * source_x[i] + b * source_y[i] + tx ||
            destination_y[i] != c * source_x[i] + d * source_y[i] + ty) return -1;
    }

    const size_t required = cells;
    if (output == NULL || capacity < required) return -2;
    size_t written = 0;
    for (int64_t output_y = 0; output_y < (int64_t)cols; ++output_y) {
        for (int64_t output_x = 0; output_x < (int64_t)rows; ++output_x) {
            const int64_t dx = output_x - tx, dy = output_y - ty;
            const int64_t source_column = (d * dx - b * dy) / determinant;
            const int64_t source_row = (-c * dx + a * dy) / determinant;
            output[written++] = (source_column >= 0 && source_column < (int64_t)cols &&
                                 source_row >= 0 && source_row < (int64_t)rows)
                ? pixels[(size_t)source_row * cols + (size_t)source_column] : 0;
        }
    }
    return (int64_t)required;
}
