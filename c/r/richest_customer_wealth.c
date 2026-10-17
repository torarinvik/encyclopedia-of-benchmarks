#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 32
#define MAX_COLUMNS 32
#define MAX_INPUT_LENGTH (2 + MAX_ROWS * MAX_COLUMNS + 1)
#define MAX_AMOUNT INT64_C(1000000)

int64_t richest_customer_wealth(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)input[0], columns = (size_t)input[1];
    if (length != 2 + rows * columns) return -1;
    int64_t richest = 0;
    for (size_t row = 0; row < rows; ++row) {
        int64_t wealth = 0;
        for (size_t column = 0; column < columns; ++column) {
            const int64_t amount = input[2 + row * columns + column];
            if (amount < 0 || amount > MAX_AMOUNT) return -1;
            wealth += amount;
        }
        if (wealth > richest) richest = wealth;
    }
    return richest;
}
