#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define BLOCK 5
#define MAX_LINE 4
#define ROW_WORDS 80
#define INVALID_RESULT (-1.0e300)

static int solve_block(const double matrix[BLOCK][BLOCK],
                       const double right[BLOCK][BLOCK + 1],
                       double answer[BLOCK][BLOCK + 1]) {
    double work[BLOCK][2 * BLOCK + 1];
    for (size_t r = 0; r < BLOCK; ++r) {
        for (size_t c = 0; c < BLOCK; ++c) work[r][c] = matrix[r][c];
        for (size_t c = 0; c < BLOCK + 1; ++c) work[r][BLOCK + c] = right[r][c];
    }
    for (size_t pivot = 0; pivot < BLOCK; ++pivot) {
        size_t best = pivot;
        for (size_t r = pivot + 1; r < BLOCK; ++r) {
            if (fabs(work[r][pivot]) > fabs(work[best][pivot])) best = r;
        }
        if (work[best][pivot] == 0.0) return 0;
        if (best != pivot) {
            for (size_t c = 0; c < 2 * BLOCK + 1; ++c) {
                double temporary = work[pivot][c];
                work[pivot][c] = work[best][c];
                work[best][c] = temporary;
            }
        }
        double divisor = work[pivot][pivot];
        for (size_t c = pivot; c < 2 * BLOCK + 1; ++c) work[pivot][c] /= divisor;
        for (size_t r = 0; r < BLOCK; ++r) {
            if (r == pivot) continue;
            double factor = work[r][pivot];
            for (size_t c = pivot; c < 2 * BLOCK + 1; ++c) {
                work[r][c] -= factor * work[pivot][c];
            }
        }
    }
    for (size_t r = 0; r < BLOCK; ++r) {
        for (size_t c = 0; c < BLOCK + 1; ++c) answer[r][c] = work[r][BLOCK + c];
    }
    return 1;
}

double npb_bt_5x5_block_tridiagonal(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + ROW_WORDS * MAX_LINE) return INVALID_RESULT;
    int64_t raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_LINE) return INVALID_RESULT;
    size_t n = (size_t)raw_n;
    if (length != 1 + ROW_WORDS * n) return INVALID_RESULT;

    double lower[MAX_LINE][BLOCK][BLOCK] = {{{0.0}}};
    double diagonal[MAX_LINE][BLOCK][BLOCK] = {{{0.0}}};
    double upper[MAX_LINE][BLOCK][BLOCK] = {{{0.0}}};
    double rhs[MAX_LINE][BLOCK] = {{0.0}};
    for (size_t row = 0; row < n; ++row) {
        size_t cursor = 1 + ROW_WORDS * row;
        for (size_t which = 0; which < 3; ++which) {
            for (size_t r = 0; r < BLOCK; ++r) {
                for (size_t c = 0; c < BLOCK; ++c) {
                    int64_t value = input[cursor++];
                    if (which == 1) {
                        if (r == c) {
                            if (value < 40 || value > 64) return INVALID_RESULT;
                        } else if (value < -2 || value > 2) return INVALID_RESULT;
                        diagonal[row][r][c] = (double)value;
                    } else {
                        if (value < -2 || value > 2) return INVALID_RESULT;
                        if (which == 0) lower[row][r][c] = (double)value;
                        else upper[row][r][c] = (double)value;
                    }
                }
            }
        }
        for (size_t r = 0; r < BLOCK; ++r) {
            int64_t value = input[cursor++];
            if (value < -1000 || value > 1000) return INVALID_RESULT;
            rhs[row][r] = (double)value;
        }
        if (row == 0) {
            for (size_t r = 0; r < BLOCK; ++r) for (size_t c = 0; c < BLOCK; ++c) {
                if (lower[row][r][c] != 0.0) return INVALID_RESULT;
            }
        }
        if (row + 1 == n) {
            for (size_t r = 0; r < BLOCK; ++r) for (size_t c = 0; c < BLOCK; ++c) {
                if (upper[row][r][c] != 0.0) return INVALID_RESULT;
            }
        }
        for (size_t r = 0; r < BLOCK; ++r) {
            double off_diagonal = 0.0;
            for (size_t c = 0; c < BLOCK; ++c) {
                if (r != c) off_diagonal += fabs(diagonal[row][r][c]);
                off_diagonal += fabs(lower[row][r][c]) + fabs(upper[row][r][c]);
            }
            if (diagonal[row][r][r] <= off_diagonal) return INVALID_RESULT;
        }
    }

    double modified_upper[MAX_LINE][BLOCK][BLOCK] = {{{0.0}}};
    double modified_rhs[MAX_LINE][BLOCK] = {{0.0}};
    for (size_t row = 0; row < n; ++row) {
        double schur[BLOCK][BLOCK];
        double reduced[BLOCK];
        double right[BLOCK][BLOCK + 1];
        double solved[BLOCK][BLOCK + 1];
        for (size_t r = 0; r < BLOCK; ++r) {
            reduced[r] = rhs[row][r];
            for (size_t c = 0; c < BLOCK; ++c) {
                schur[r][c] = diagonal[row][r][c];
                if (row > 0) {
                    for (size_t k = 0; k < BLOCK; ++k) {
                        schur[r][c] -= lower[row][r][k] * modified_upper[row - 1][k][c];
                    }
                }
            }
            if (row > 0) {
                for (size_t k = 0; k < BLOCK; ++k) reduced[r] -= lower[row][r][k] * modified_rhs[row - 1][k];
            }
            for (size_t c = 0; c < BLOCK; ++c) right[r][c] = upper[row][r][c];
            right[r][BLOCK] = reduced[r];
        }
        if (!solve_block(schur, right, solved)) return INVALID_RESULT;
        for (size_t r = 0; r < BLOCK; ++r) {
            modified_rhs[row][r] = solved[r][BLOCK];
            for (size_t c = 0; c < BLOCK; ++c) modified_upper[row][r][c] = solved[r][c];
        }
    }

    double solution[MAX_LINE][BLOCK] = {{0.0}};
    for (size_t r = 0; r < BLOCK; ++r) solution[n - 1][r] = modified_rhs[n - 1][r];
    for (size_t row = n - 1; row-- > 0;) {
        for (size_t r = 0; r < BLOCK; ++r) {
            solution[row][r] = modified_rhs[row][r];
            for (size_t c = 0; c < BLOCK; ++c) {
                solution[row][r] -= modified_upper[row][r][c] * solution[row + 1][c];
            }
        }
    }
    double checksum = 0.0;
    for (size_t row = 0; row < n; ++row) for (size_t r = 0; r < BLOCK; ++r) {
        checksum += (double)(row * BLOCK + r + 1) * solution[row][r];
    }
    return isfinite(checksum) ? checksum : INVALID_RESULT;
}
