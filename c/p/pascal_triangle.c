#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 30
#define HASH_MOD 1000000007LL

int64_t pascal_triangle_benchmark(const int64_t *values, size_t length)
{
    if (length != 1 || values[0] < 0 || values[0] > MAX_ROWS) return -1;
    const size_t row_count = (size_t)values[0];
    int64_t row[MAX_ROWS] = {0};
    row[0] = 1;
    int64_t hash = 0;
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        for (size_t column = row_index; column > 0; --column) {
            row[column] += row[column - 1];
        }
        for (size_t column = 0; column <= row_index; ++column) {
            hash = (hash * 31 + row[column] % HASH_MOD) % HASH_MOD;
        }
    }
    return hash;
}
