module npb_bt_5x5_block_tridiagonal;

extern fn double fabs(double value);

const usz BLOCK = 5;
const usz MAX_LINE = 4;
const usz ROW_WORDS = 80;
const double INVALID_RESULT = -1.0e300;

fn bool solve_block(double* matrix, double* right, double* answer) {
    double[55] work = zeroed;
    for (usz r = 0; r < BLOCK; r += 1) {
        for (usz c = 0; c < BLOCK; c += 1) work[r * 11 + c] = matrix[r * 5 + c];
        for (usz c = 0; c < 6; c += 1) work[r * 11 + 5 + c] = right[r * 6 + c];
    }
    for (usz pivot = 0; pivot < BLOCK; pivot += 1) {
        usz best = pivot;
        for (usz r = pivot + 1; r < BLOCK; r += 1) {
            if (fabs(work[r * 11 + pivot]) > fabs(work[best * 11 + pivot])) best = r;
        }
        if (work[best * 11 + pivot] == 0.0) return false;
        if (best != pivot) for (usz c = 0; c < 11; c += 1) {
            double temporary = work[pivot * 11 + c];
            work[pivot * 11 + c] = work[best * 11 + c];
            work[best * 11 + c] = temporary;
        }
        double divisor = work[pivot * 11 + pivot];
        for (usz c = pivot; c < 11; c += 1) work[pivot * 11 + c] /= divisor;
        for (usz r = 0; r < BLOCK; r += 1) {
            if (r == pivot) continue;
            double factor = work[r * 11 + pivot];
            for (usz c = pivot; c < 11; c += 1) work[r * 11 + c] -= factor * work[pivot * 11 + c];
        }
    }
    for (usz r = 0; r < BLOCK; r += 1) for (usz c = 0; c < 6; c += 1) {
        answer[r * 6 + c] = work[r * 11 + 5 + c];
    }
    return true;
}

fn double npb_bt_5x5_block_tridiagonal(long* values, usz length)
    @export("npb_bt_5x5_block_tridiagonal") {
    if (values == null || length < 1 || length > 321) return INVALID_RESULT;
    long raw_n = values[0];
    if (raw_n < 2 || raw_n > 4) return INVALID_RESULT;
    usz n = (usz)raw_n;
    if (length != 1 + ROW_WORDS * n) return INVALID_RESULT;

    double[100] lower = zeroed, diagonal = zeroed, upper = zeroed;
    double[20] rhs = zeroed;
    for (usz row = 0; row < n; row += 1) {
        usz cursor = 1 + ROW_WORDS * row;
        for (usz which = 0; which < 3; which += 1) {
            for (usz r = 0; r < BLOCK; r += 1) for (usz c = 0; c < BLOCK; c += 1) {
                long value = values[cursor]; cursor += 1;
                if (which == 1) {
                    if (r == c) { if (value < 40 || value > 64) return INVALID_RESULT; }
                    else if (value < -2 || value > 2) return INVALID_RESULT;
                    diagonal[row * 25 + r * 5 + c] = (double)value;
                } else {
                    if (value < -2 || value > 2) return INVALID_RESULT;
                    if (which == 0) lower[row * 25 + r * 5 + c] = (double)value;
                    else upper[row * 25 + r * 5 + c] = (double)value;
                }
            }
        }
        for (usz r = 0; r < BLOCK; r += 1) {
            long value = values[cursor]; cursor += 1;
            if (value < -1000 || value > 1000) return INVALID_RESULT;
            rhs[row * 5 + r] = (double)value;
        }
        for (usz r = 0; r < BLOCK; r += 1) for (usz c = 0; c < BLOCK; c += 1) {
            if (row == 0 && lower[row * 25 + r * 5 + c] != 0.0) return INVALID_RESULT;
            if (row + 1 == n && upper[row * 25 + r * 5 + c] != 0.0) return INVALID_RESULT;
        }
        for (usz r = 0; r < BLOCK; r += 1) {
            double off_diagonal = 0.0;
            for (usz c = 0; c < BLOCK; c += 1) {
                if (r != c) off_diagonal += fabs(diagonal[row * 25 + r * 5 + c]);
                off_diagonal += fabs(lower[row * 25 + r * 5 + c]) + fabs(upper[row * 25 + r * 5 + c]);
            }
            if (diagonal[row * 25 + r * 5 + r] <= off_diagonal) return INVALID_RESULT;
        }
    }

    double[100] modified_upper = zeroed;
    double[20] modified_rhs = zeroed;
    for (usz row = 0; row < n; row += 1) {
        double[25] schur = zeroed;
        double[30] right = zeroed, solved = zeroed;
        for (usz r = 0; r < BLOCK; r += 1) {
            double reduced = rhs[row * 5 + r];
            for (usz c = 0; c < BLOCK; c += 1) {
                double value = diagonal[row * 25 + r * 5 + c];
                if (row > 0) for (usz k = 0; k < BLOCK; k += 1) {
                    value -= lower[row * 25 + r * 5 + k] * modified_upper[(row - 1) * 25 + k * 5 + c];
                }
                schur[r * 5 + c] = value;
            }
            if (row > 0) for (usz k = 0; k < BLOCK; k += 1) {
                reduced -= lower[row * 25 + r * 5 + k] * modified_rhs[(row - 1) * 5 + k];
            }
            for (usz c = 0; c < BLOCK; c += 1) right[r * 6 + c] = upper[row * 25 + r * 5 + c];
            right[r * 6 + 5] = reduced;
        }
        if (!solve_block(&schur[0], &right[0], &solved[0])) return INVALID_RESULT;
        for (usz r = 0; r < BLOCK; r += 1) {
            modified_rhs[row * 5 + r] = solved[r * 6 + 5];
            for (usz c = 0; c < BLOCK; c += 1) modified_upper[row * 25 + r * 5 + c] = solved[r * 6 + c];
        }
    }
    double[20] solution = zeroed;
    for (usz r = 0; r < BLOCK; r += 1) solution[(n - 1) * 5 + r] = modified_rhs[(n - 1) * 5 + r];
    usz row = n - 1;
    while (row > 0) {
        row -= 1;
        for (usz r = 0; r < BLOCK; r += 1) {
            double value = modified_rhs[row * 5 + r];
            for (usz c = 0; c < BLOCK; c += 1) value -= modified_upper[row * 25 + r * 5 + c] * solution[(row + 1) * 5 + c];
            solution[row * 5 + r] = value;
        }
    }
    double checksum = 0.0;
    for (usz q = 0; q < n * 5; q += 1) checksum += (double)(q + 1) * solution[q];
    return checksum;
}
