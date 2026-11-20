#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 39
#define MODULUS INT64_C(1000000007)

int64_t number_of_ways_of_cutting_a_pizza(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t rows64 = input[0];
    const int64_t columns64 = input[1];
    const int64_t cuts64 = input[2];
    if (rows64 < 1 || rows64 > 6 || columns64 < 1 || columns64 > 6
        || cuts64 < 0 || cuts64 > 5
        || length != 3 + (size_t)(rows64 * columns64)) return -1;
    const size_t rows = (size_t)rows64;
    const size_t columns = (size_t)columns64;
    const size_t cuts = (size_t)cuts64;

    int64_t suffix[49] = {0};
    const size_t stride = 7;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            const int64_t cell = input[3 + row * columns + column];
            if (cell != 0 && cell != 1) return -1;
        }
    }
    for (size_t row = rows; row-- > 0;) {
        for (size_t column = columns; column-- > 0;) {
            const int64_t cell = input[3 + row * columns + column];
            suffix[row * stride + column] = cell
                + suffix[(row + 1) * stride + column]
                + suffix[row * stride + column + 1]
                - suffix[(row + 1) * stride + column + 1];
        }
    }

    int64_t previous[49] = {0};
    int64_t current[49] = {0};
    for (size_t row = 0; row < rows; ++row)
        for (size_t column = 0; column < columns; ++column)
            previous[row * stride + column] = suffix[row * stride + column] > 0 ? 1 : 0;

    for (size_t remaining = 1; remaining <= cuts; ++remaining) {
        for (size_t index = 0; index < 49; ++index) current[index] = 0;
        for (size_t row = rows; row-- > 0;) {
            for (size_t column = columns; column-- > 0;) {
                const size_t origin = row * stride + column;
                int64_t ways = 0;
                for (size_t cut_row = row + 1; cut_row < rows; ++cut_row) {
                    if (suffix[origin] - suffix[cut_row * stride + column] > 0)
                        ways += previous[cut_row * stride + column];
                }
                for (size_t cut_column = column + 1; cut_column < columns; ++cut_column) {
                    if (suffix[origin] - suffix[row * stride + cut_column] > 0)
                        ways += previous[row * stride + cut_column];
                }
                current[origin] = ways % MODULUS;
            }
        }
        for (size_t index = 0; index < 49; ++index) previous[index] = current[index];
    }
    return previous[0];
}
