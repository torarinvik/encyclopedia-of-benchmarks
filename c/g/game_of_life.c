/* Compute one finite, non-wrapping Conway Game of Life generation. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 32

int64_t game_of_life(const int64_t *input, size_t length, uint8_t *output,
                     size_t output_capacity)
{
    if (input == NULL || length == 0) return -1;
    const int64_t side_value = input[0];
    if (side_value < 0 || side_value > MAX_SIDE) return -1;
    const size_t side = (size_t)side_value;
    const size_t cell_count = side * side;
    if (length != cell_count + 1) return -1;
    for (size_t index = 0; index < cell_count; ++index) {
        if (input[index + 1] != 0 && input[index + 1] != 1) return -1;
    }
    if (output_capacity < cell_count || (cell_count != 0 && output == NULL)) return -2;

    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            unsigned neighbors = 0;
            for (int row_delta = -1; row_delta <= 1; ++row_delta) {
                for (int column_delta = -1; column_delta <= 1; ++column_delta) {
                    if (row_delta == 0 && column_delta == 0) continue;
                    const int64_t neighbor_row = (int64_t)row + row_delta;
                    const int64_t neighbor_column = (int64_t)column + column_delta;
                    if (neighbor_row >= 0 && neighbor_row < side_value &&
                        neighbor_column >= 0 && neighbor_column < side_value &&
                        input[1 + (size_t)neighbor_row * side + (size_t)neighbor_column] == 1) {
                        ++neighbors;
                    }
                }
            }
            const size_t index = row * side + column;
            const int alive = input[index + 1] == 1;
            output[index] = (uint8_t)(alive ? (neighbors == 2 || neighbors == 3)
                                            : (neighbors == 3));
        }
    }
    return (int64_t)cell_count;
}
