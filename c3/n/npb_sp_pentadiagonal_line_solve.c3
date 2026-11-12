module npb_sp_pentadiagonal_line_solve;

import "core:math";
extern fn double trunc(double value);

const usz MIN_N = 5;
const usz MAX_N = 16;

fn long npb_sp_pentadiagonal_line_solve(double* input, usz length,
        double* output, usz capacity) @export("npb_sp_pentadiagonal_line_solve") {
    if (input == null || length < 31 || length > 97) return -1;
    double n_value = input[0];
    if (n_value != n_value || trunc(n_value) != n_value || n_value < 5.0 || n_value > 16.0) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 6 * n) return -1;
    double* lower2 = input + 1;
    double* lower1 = lower2 + n;
    double* diagonal = lower1 + n;
    double* upper1 = diagonal + n;
    double* upper2 = upper1 + n;
    double* rhs = upper2 + n;
    if (lower2[0] != 0.0 || lower2[1] != 0.0 || lower1[0] != 0.0 ||
        upper1[n-1] != 0.0 || upper2[n-2] != 0.0 || upper2[n-1] != 0.0) return -1;
    for (usz row = 0; row < n; row += 1) {
        double bands[4] = {lower2[row], lower1[row], upper1[row], upper2[row]};
        double radius = 0.0;
        for (usz band = 0; band < 4; band += 1) {
            if (bands[band] != bands[band] || math.abs(bands[band]) > 2.0) return -1;
            radius += math.abs(bands[band]);
        }
        if (diagonal[row] != diagonal[row] || diagonal[row] < 5.0 || diagonal[row] > 16.0 ||
            rhs[row] != rhs[row] || rhs[row] < -64.0 || rhs[row] > 64.0 ||
            diagonal[row] - radius < 0.25) return -1;
    }
    if (output == null || capacity < n) return -2;
    double lo1[MAX_N] = {0.0}, diag[MAX_N] = {0.0}, up1[MAX_N] = {0.0};
    double up2[MAX_N] = {0.0}, work_rhs[MAX_N] = {0.0}, solution[MAX_N] = {0.0};
    for (usz row = 0; row < n; row += 1) {
        lo1[row] = lower1[row]; diag[row] = diagonal[row];
        up1[row] = upper1[row]; up2[row] = upper2[row]; work_rhs[row] = rhs[row];
    }
    for (usz pivot_row = 0; pivot_row < n; pivot_row += 1) {
        double pivot = diag[pivot_row];
        if (pivot_row + 1 < n) {
            usz row = pivot_row + 1;
            double factor = lo1[row] / pivot;
            diag[row] -= factor * up1[pivot_row];
            up1[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
        if (pivot_row + 2 < n) {
            usz row = pivot_row + 2;
            double factor = lower2[row] / pivot;
            lo1[row] -= factor * up1[pivot_row];
            diag[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
    }
    usz back = n;
    while (back > 0) {
        back -= 1;
        double value = work_rhs[back];
        if (back + 1 < n) value -= up1[back] * solution[back+1];
        if (back + 2 < n) value -= up2[back] * solution[back+2];
        solution[back] = value / diag[back];
    }
    for (usz row = 0; row < n; row += 1) output[row] = solution[row];
    return (long)n;
}
