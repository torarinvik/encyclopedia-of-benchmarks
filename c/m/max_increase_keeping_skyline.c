/* Return the total allowable increase while preserving every row and column skyline. */
#include <stddef.h>
#include <stdint.h>

#define MAX_GRID_SIZE 50

int64_t max_increase_keeping_skyline(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE) return -1;
    if (values[0] < 2 || values[0] > MAX_GRID_SIZE) return -1;
    const size_t size = (size_t)values[0];
    if (length != 1 + size * size) return -1;

    uint8_t row_max[MAX_GRID_SIZE] = {0};
    uint8_t column_max[MAX_GRID_SIZE] = {0};
    uint64_t tallest = 0;
    uint32_t height_sum = 0;
    for (size_t row = 0; row < size; ++row) {
        uint8_t row_tallest = 0;
        size_t start = 1 + row * size;
        for (size_t column = 0; column < size; ++column) {
            uint64_t value = (uint64_t)values[start + column];
            tallest = value > tallest ? value : tallest;
            height_sum += (uint32_t)value;
            uint8_t height = (uint8_t)value;
            row_tallest = height > row_tallest ? height : row_tallest;
            column_max[column] = height > column_max[column] ? height : column_max[column];
        }
        row_max[row] = row_tallest;
    }
    if (tallest > 100) return -1;

    uint32_t skyline_sum = 0;
    if (size <= 10) {
        for (size_t row = 0; row < size; ++row) {
            uint8_t row_height = row_max[row];
            for (size_t column = 0; column < size; ++column) {
                uint8_t column_height = column_max[column];
                skyline_sum += (uint32_t)(row_height < column_height ? row_height : column_height);
            }
        }
    } else {
        uint8_t row_counts[101] = {0};
        uint8_t column_counts[101] = {0};
        uint8_t lowest = 100;
        for (size_t index = 0; index < size; ++index) {
            lowest = row_max[index] < lowest ? row_max[index] : lowest;
            lowest = column_max[index] < lowest ? column_max[index] : lowest;
            row_counts[row_max[index]]++;
            column_counts[column_max[index]]++;
        }
        uint32_t rows_above = (uint32_t)size;
        uint32_t columns_above = (uint32_t)size;
        skyline_sum = rows_above * columns_above * lowest;
        for (size_t height = lowest; height < tallest; ++height) {
            rows_above -= row_counts[height];
            columns_above -= column_counts[height];
            skyline_sum += rows_above * columns_above;
        }
    }
    return (int64_t)(skyline_sum - height_sum);
}
