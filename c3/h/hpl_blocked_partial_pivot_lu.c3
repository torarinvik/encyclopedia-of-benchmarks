module hpl_blocked_partial_pivot_lu;

const usz MAX_N = 8;
const usz MAX_INPUT_LENGTH = 66;
const usz MAX_OUTPUT_ELEMENTS = 72;

fn bool finite_value(double x) { return x == x && x >= -1e308 && x <= 1e308; }
fn bool exact_integer(double x, long lo, long hi, long* out) {
    if (!finite_value(x) || x < (double)lo || x > (double)hi) return false;
    long value = (long)x;
    if ((double)value != x) return false;
    *out = value;
    return true;
}

fn long hpl_blocked_partial_pivot_lu(double* input, usz input_length,
                                     double* output, usz output_capacity)
    @export("hpl_blocked_partial_pivot_lu") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1L;
    long n_value;
    if (!exact_integer(input[0], 2, (long)MAX_N, &n_value)) return -1L;
    usz n = (usz)n_value;
    if (input_length != 1 + n * n) return -1L;

    double[MAX_N * MAX_N] a = zeroed;
    for (usz i = 0; i < n * n; i++) {
        long value;
        if (!exact_integer(input[i + 1], -16, 16, &value)) return -1L;
        a[i] = (double)value;
    }
    usz[MAX_N] pivots = zeroed;
    usz panel = 0;
    while (panel < n) {
        usz panel_end = panel + 2;
        if (panel_end > n) panel_end = n;
        usz col = panel;
        while (col < panel_end) {
            usz pivot_row = col;
            double pivot_magnitude = math_abs(a[col * n + col]);
            for (usz row = col + 1; row < n; row++) {
                double magnitude = math_abs(a[row * n + col]);
                if (magnitude > pivot_magnitude) {
                    pivot_magnitude = magnitude;
                    pivot_row = row;
                }
            }
            if (!finite_value(pivot_magnitude) || pivot_magnitude == 0.0) return -1L;
            pivots[col] = pivot_row;
            if (pivot_row != col) {
                for (usz j = 0; j < n; j++) {
                    double temp = a[col * n + j];
                    a[col * n + j] = a[pivot_row * n + j];
                    a[pivot_row * n + j] = temp;
                }
            }
            double diagonal = a[col * n + col];
            if (!finite_value(diagonal) || diagonal == 0.0) return -1L;
            for (usz row = col + 1; row < n; row++) {
                a[row * n + col] = a[row * n + col] / diagonal;
                if (!finite_value(a[row * n + col])) return -1L;
                double multiplier = a[row * n + col];
                for (usz j = col + 1; j < panel_end; j++) {
                    a[row * n + j] = a[row * n + j] - multiplier * a[col * n + j];
                    if (!finite_value(a[row * n + j])) return -1L;
                }
            }
            col++;
        }
        for (usz row = panel; row < panel_end; row++) {
            for (usz j = panel_end; j < n; j++) {
                double value = a[row * n + j];
                for (usz inner = panel; inner < row; inner++)
                    value = value - a[row * n + inner] * a[inner * n + j];
                if (!finite_value(value)) return -1L;
                a[row * n + j] = value;
            }
        }
        for (usz row = panel_end; row < n; row++) {
            for (usz j = panel_end; j < n; j++) {
                double update = 0.0;
                for (usz inner = panel; inner < panel_end; inner++)
                    update = update + a[row * n + inner] * a[inner * n + j];
                a[row * n + j] = a[row * n + j] - update;
                if (!finite_value(a[row * n + j])) return -1L;
            }
        }
        panel = panel_end;
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    for (usz i = 0; i < n; i++) staged[i] = (double)pivots[i];
    for (usz i = 0; i < n * n; i++) {
        if (!finite_value(a[i])) return -1L;
        staged[n + i] = a[i];
    }
    usz output_length = n + n * n;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz i = 0; i < output_length; i++) output[i] = staged[i];
    return (long)output_length;
}
