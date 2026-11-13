#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

int64_t sparse_supernodal_cholesky(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 56) return -1;
    int64_t n_arg = input[0], s_arg = input[1];
    if (n_arg < 1 || n_arg > 8 || s_arg < 1 || s_arg > n_arg) return -1;
    size_t n = (size_t)n_arg, s = (size_t)s_arg, triangle = n * (n + 1) / 2;
    if (length != 3 + s + n + triangle) return -1;
    int boundary[9], masks[8], slot[8][8];
    for (size_t i = 0; i <= s; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > (int64_t)n) return -1;
        boundary[i] = (int)input[2 + i];
        if (i && boundary[i] <= boundary[i - 1]) return -1;
    }
    if (boundary[0] != 0 || boundary[s] != (int)n) return -1;
    for (size_t i = 0; i < n; ++i) {
        int64_t mask = input[3 + s + i];
        if (mask < 0 || mask >= ((int64_t)1 << (i + 1)) || !(mask & ((int64_t)1 << i))) return -1;
        masks[i] = (int)mask;
        for (size_t j = 0; j < n; ++j) slot[i][j] = -1;
    }
    for (size_t col = 0; col < n; ++col)
        for (size_t row = col + 1; row < n; ++row)
            if (masks[row] & (1 << col))
                for (size_t lower = row + 1; lower < n; ++lower)
                    if ((masks[lower] & (1 << col)) && !(masks[lower] & (1 << row))) return -1;
    for (size_t b = 0; b < s; ++b) {
        int start = boundary[b], end = boundary[b + 1];
        for (int row = start; row < end; ++row)
            for (int col = start; col < row; ++col)
                if (!(masks[row] & (1 << col))) return -1;
        int block = ((1 << end) - 1) ^ ((1 << start) - 1);
        for (int row = end; row < (int)n; ++row) {
            int selected = masks[row] & block;
            if (selected != 0 && selected != block) return -1;
        }
    }
    double sparse[36] = {0};
    size_t cursor = 3 + s + n, used = 0;
    for (size_t row = 0; row < n; ++row) {
        for (size_t col = 0; col <= row; ++col) {
            int64_t value = input[cursor++];
            if (value < -1000000 || value > 1000000) return -1;
            if (!(masks[row] & (1 << col))) {
                if (value != 0) return -1;
            } else {
                slot[row][col] = (int)used;
                sparse[used++] = (double)value / 1000.0;
            }
        }
    }
    for (size_t b = 0; b < s; ++b) {
        int start = boundary[b], end = boundary[b + 1];
        for (int col = start; col < end; ++col) {
            double pivot = sparse[slot[col][col]];
            if (!isfinite(pivot) || pivot <= 0) return -1;
            sparse[slot[col][col]] = sqrt(pivot);
            for (int row = col + 1; row < end; ++row)
                sparse[slot[row][col]] /= sparse[slot[col][col]];
            for (int row = col + 1; row < end; ++row)
                for (int target = col + 1; target <= row; ++target)
                    sparse[slot[row][target]] -= sparse[slot[row][col]] * sparse[slot[target][col]];
        }
        for (int row = end; row < (int)n; ++row) if (masks[row] & (1 << start)) {
            for (int col = start; col < end; ++col) {
                double value = sparse[slot[row][col]];
                for (int k = start; k < col; ++k) value -= sparse[slot[row][k]] * sparse[slot[col][k]];
                sparse[slot[row][col]] = value / sparse[slot[col][col]];
            }
        }
        for (int row = end; row < (int)n; ++row) if (masks[row] & (1 << start))
            for (int target = end; target <= row; ++target) if (masks[target] & (1 << start))
                for (int k = start; k < end; ++k)
                    sparse[slot[row][target]] -= sparse[slot[row][k]] * sparse[slot[target][k]];
    }
    size_t required = triangle * 8;
    if (output == NULL || capacity < required) return -2;
    size_t offset = 0;
    for (size_t row = 0; row < n; ++row) for (size_t col = 0; col <= row; ++col) {
        double value = slot[row][col] < 0 ? 0.0 : sparse[slot[row][col]];
        uint64_t bits;
        memcpy(&bits, &value, sizeof bits);
        for (size_t byte = 0; byte < 8; ++byte) output[offset++] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
