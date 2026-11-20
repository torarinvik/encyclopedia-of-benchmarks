/* Zhang-Suen binary image thinning with simultaneous phase deletions. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 32
#define MAX_COLUMNS 32
#define MAX_CELLS (MAX_ROWS * MAX_COLUMNS)
#define MAX_PARSEABLE_INPUT_LENGTH (2 + MAX_CELLS + 1)

static int thin_phase(uint8_t *image, uint8_t *marked, size_t rows,
                      size_t columns, int second_phase)
{
    const size_t cells = rows * columns;
    for (size_t index = 0; index < cells; ++index) marked[index] = 0;
    int changed = 0;
    for (size_t row = 1; row + 1 < rows; ++row) {
        for (size_t column = 1; column + 1 < columns; ++column) {
            const size_t index = row * columns + column;
            if (image[index] == 0) continue;
            const uint8_t p2 = image[index - columns];
            const uint8_t p3 = image[index - columns + 1];
            const uint8_t p4 = image[index + 1];
            const uint8_t p5 = image[index + columns + 1];
            const uint8_t p6 = image[index + columns];
            const uint8_t p7 = image[index + columns - 1];
            const uint8_t p8 = image[index - 1];
            const uint8_t p9 = image[index - columns - 1];
            const uint8_t ring[9] = {p2, p3, p4, p5, p6, p7, p8, p9, p2};
            unsigned black_neighbors = 0;
            unsigned transitions = 0;
            for (size_t neighbor = 0; neighbor < 8; ++neighbor) {
                black_neighbors += ring[neighbor];
                if (ring[neighbor] == 0 && ring[neighbor + 1] == 1) ++transitions;
            }
            if (black_neighbors < 2 || black_neighbors > 6 || transitions != 1) continue;
            int blocks_deletion;
            if (second_phase) {
                blocks_deletion = (p2 && p4 && p8) || (p2 && p6 && p8);
            } else {
                blocks_deletion = (p2 && p4 && p6) || (p4 && p6 && p8);
            }
            if (blocks_deletion) continue;
            marked[index] = 1;
            changed = 1;
        }
    }
    if (changed) {
        for (size_t index = 0; index < cells; ++index) {
            if (marked[index]) image[index] = 0;
        }
    }
    return changed;
}

int64_t zhang_suen_thinning(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (size_t index = 0; index < cells; ++index) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == NULL || output_capacity < cells) return -2;

    uint8_t image[MAX_CELLS] = {0};
    uint8_t marked[MAX_CELLS] = {0};
    for (size_t index = 0; index < cells; ++index) image[index] = (uint8_t)input[index + 2];
    for (;;) {
        const int first_changed = thin_phase(image, marked, rows, columns, 0);
        const int second_changed = thin_phase(image, marked, rows, columns, 1);
        if (!first_changed && !second_changed) break;
    }
    for (size_t index = 0; index < cells; ++index) output[index] = image[index];
    return (int64_t)cells;
}
