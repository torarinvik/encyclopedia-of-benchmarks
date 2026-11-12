/* Clean-room bounded scalar pentadiagonal line solver for the NPB SP profile. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_N 5
#define MAX_N 16
#define MAX_INPUT (1 + 6 * MAX_N)

int64_t npb_sp_pentadiagonal_line_solve(const double *input, size_t length,
                                        double *output, size_t capacity) {
    if (input == NULL || length < 1 + 6 * MIN_N || length > MAX_INPUT) return -1;
    const double n_value = input[0];
    if (!isfinite(n_value) || trunc(n_value) != n_value || n_value < MIN_N || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 6 * n) return -1;
    const double *lower2 = input + 1;
    const double *lower1 = lower2 + n;
    const double *diagonal = lower1 + n;
    const double *upper1 = diagonal + n;
    const double *upper2 = upper1 + n;
    const double *rhs = upper2 + n;
    if (lower2[0] != 0.0 || lower2[1] != 0.0 || lower1[0] != 0.0 ||
        upper1[n - 1] != 0.0 || upper2[n - 2] != 0.0 || upper2[n - 1] != 0.0) return -1;
    for (size_t row = 0; row < n; ++row) {
        const double bands[4] = {lower2[row], lower1[row], upper1[row], upper2[row]};
        double radius = 0.0;
        for (size_t band = 0; band < 4; ++band) {
            if (!isfinite(bands[band]) || fabs(bands[band]) > 2.0) return -1;
            radius += fabs(bands[band]);
        }
        if (!isfinite(diagonal[row]) || diagonal[row] < 5.0 || diagonal[row] > 16.0 ||
            !isfinite(rhs[row]) || rhs[row] < -64.0 || rhs[row] > 64.0 ||
            diagonal[row] - radius < 0.25) return -1;
    }
    if (output == NULL || capacity < n) return -2;

    double lo1[MAX_N], diag[MAX_N], up1[MAX_N], up2[MAX_N], work_rhs[MAX_N], solution[MAX_N];
    for (size_t row = 0; row < n; ++row) {
        lo1[row] = lower1[row]; diag[row] = diagonal[row];
        up1[row] = upper1[row]; up2[row] = upper2[row]; work_rhs[row] = rhs[row];
    }
    for (size_t pivot_row = 0; pivot_row < n; ++pivot_row) {
        const double pivot = diag[pivot_row];
        if (pivot_row + 1 < n) {
            const size_t row = pivot_row + 1;
            const double factor = lo1[row] / pivot;
            diag[row] -= factor * up1[pivot_row];
            up1[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
        if (pivot_row + 2 < n) {
            const size_t row = pivot_row + 2;
            const double factor = lower2[row] / pivot;
            lo1[row] -= factor * up1[pivot_row];
            diag[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
    }
    for (size_t back = n; back-- > 0;) {
        double value = work_rhs[back];
        if (back + 1 < n) value -= up1[back] * solution[back + 1];
        if (back + 2 < n) value -= up2[back] * solution[back + 2];
        solution[back] = value / diag[back];
    }
    for (size_t row = 0; row < n; ++row) output[row] = solution[row];
    return (int64_t)n;
}
