/* Retrieve one row-major flattened index from a rectangular matrix. */
#include <stddef.h>
#include <stdint.h>
#define MAX_DIMENSION 32
#define MAX_VALUE 1000000
int64_t index_2d_array_in_1d(const int64_t *input, size_t length) {
    if (!input || length < 4) return -1;
    int64_t rows=input[0], cols=input[1], index=input[2];
    if (rows < 1 || rows > MAX_DIMENSION || cols < 1 || cols > MAX_DIMENSION) return -1;
    size_t cells=(size_t)rows*(size_t)cols;
    if (length != cells+3 || index < 0 || (uint64_t)index >= cells) return -1;
    for (size_t i=0;i<cells;i++) if (input[3+i] < 0 || input[3+i] > MAX_VALUE) return -1;
    size_t row=(size_t)index/(size_t)cols;
    size_t col=(size_t)index%(size_t)cols;
    return input[3+row*(size_t)cols+col];
}
