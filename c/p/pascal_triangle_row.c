/* Compute one row of Pascal's triangle using in-place dynamic programming. */
#include <stddef.h>
#include <stdint.h>

int64_t pascal_triangle_row(int64_t row_index, uint8_t *output, size_t output_capacity)
{
    if (row_index < 0 || row_index > 33) return -1;
    const size_t count = (size_t)row_index + 1;
    const size_t required = count * sizeof(uint32_t);
    if (output == NULL || output_capacity < required) return -2;

    uint32_t coefficients[34];
    for (size_t column = 0; column < count; ++column) coefficients[column] = 1;
    for (size_t row = 2; row <= (size_t)row_index; ++row)
        for (size_t column = row - 1; column > 0; --column)
            coefficients[column] += coefficients[column - 1];

    size_t position = 0;
    for (size_t column = 0; column < count; ++column)
        for (unsigned byte = 0; byte < 4; ++byte)
            output[position++] = (uint8_t)(coefficients[column] >> (byte * 8));
    return (int64_t)position;
}
