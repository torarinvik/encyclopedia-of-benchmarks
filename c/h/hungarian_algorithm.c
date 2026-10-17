#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 67
#define MAX_DIMENSION 8
static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    uint32_t bits = (uint32_t)value;
    for (size_t b = 0; b < 4; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}
int64_t hungarian_algorithm(const int32_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int32_t rows = input[0], cols = input[1];
    if (rows < 1 || rows > MAX_DIMENSION || cols < 1 || cols > MAX_DIMENSION || length != 2u + (size_t)rows * (size_t)cols) return -1;
    for (size_t k = 0; k < (size_t)rows * (size_t)cols; ++k) if (input[2 + k] < 0 || input[2 + k] > 1000) return -1;
    const int n = rows > cols ? rows : cols;
    int32_t a[81] = {0}, u[9] = {0}, v[9] = {0}, p[9] = {0}, way[9] = {0};
    for (int i = 0; i < rows; ++i) for (int j = 0; j < cols; ++j) a[i * 9 + j] = input[2 + i * cols + j];
    for (int i = 1; i <= n; ++i) {
        p[0] = i;
        int j0 = 0;
        int32_t minv[9];
        int used[9] = {0};
        for (int j = 0; j <= n; ++j) minv[j] = INT32_MAX;
        do {
            used[j0] = 1;
            int i0 = p[j0];
            int32_t delta = INT32_MAX;
            int j1 = 0;
            for (int j = 1; j <= n; ++j) if (!used[j]) {
                int32_t cur = a[(i0 - 1) * 9 + (j - 1)] - u[i0] - v[j];
                if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
                if (minv[j] < delta) { delta = minv[j]; j1 = j; }
            }
            for (int j = 0; j <= n; ++j) {
                if (used[j]) { u[p[j]] += delta; v[j] -= delta; }
                else minv[j] -= delta;
            }
            j0 = j1;
        } while (p[j0] != 0);
        do { int j1 = way[j0]; p[j0] = p[j1]; j0 = j1; } while (j0 != 0);
    }
    int32_t match[9];
    for (int i = 0; i < 9; ++i) match[i] = -1;
    for (int j = 1; j <= n; ++j) if (p[j] != 0) match[p[j] - 1] = j - 1;
    int32_t assignments[8], total = 0;
    for (int i = 0; i < rows; ++i) {
        int j = match[i];
        assignments[i] = j >= 0 && j < cols ? j : -1;
        if (assignments[i] >= 0) total += input[2 + i * cols + assignments[i]];
    }
    const size_t bytes = 4u * ((size_t)rows + 1u);
    if (output == NULL || capacity < bytes) return -2;
    for (int i = 0; i < rows; ++i) store_i32_le(output, 4u * (size_t)i, assignments[i]);
    store_i32_le(output, 4u * (size_t)rows, total);
    return (int64_t)bytes;
}
