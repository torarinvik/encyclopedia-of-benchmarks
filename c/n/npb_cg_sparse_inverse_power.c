#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_N = 32, MAX_OUTER = 8, MAX_CG_STEPS = 25, MAX_NNZ_PER_ROW = 6 };
static const int64_t max_micro = INT64_C(1000000000);
static const double scale_micro = 1000000.0;

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void sparse_matvec(size_t n, size_t nnz, const int64_t *values,
                          const double *vector, double *product) {
    const size_t row_ptr = 5;
    const size_t columns = row_ptr + n + 1;
    const size_t entries = columns + nnz;
    (void)nnz;
    for (size_t row = 0; row < n; ++row) {
        double sum = 0.0;
        for (size_t edge = (size_t)values[row_ptr + row];
             edge < (size_t)values[row_ptr + row + 1]; ++edge)
            sum += ((double)values[entries + edge] / scale_micro) *
                   vector[(size_t)values[columns + edge]];
        product[row] = sum;
    }
}

static int validate(const int64_t *v, size_t length, size_t *n_out,
                    size_t *outer_out, size_t *steps_out, size_t *nnz_out) {
    if (v == NULL || length < 8) return 0;
    if (v[0] < 1 || v[0] > MAX_N || v[1] < 1 || v[1] > MAX_OUTER ||
        v[2] < 1 || v[2] > MAX_CG_STEPS || v[2] > v[0] ||
        v[3] < -max_micro || v[3] > max_micro || v[4] < v[0] ||
        v[4] > v[0] * MAX_NNZ_PER_ROW) return 0;
    const size_t n = (size_t)v[0], nnz = (size_t)v[4];
    if (length != n + 6 + 2 * nnz) return 0;
    const size_t row_ptr = 5, columns = row_ptr + n + 1, entries = columns + nnz;
    if (v[row_ptr] != 0 || v[row_ptr + n] != (int64_t)nnz) return 0;
    for (size_t row = 0; row < n; ++row) {
        if (v[row_ptr + row] < 0 || v[row_ptr + row] >= v[row_ptr + row + 1] ||
            v[row_ptr + row + 1] > (int64_t)nnz) return 0;
        int64_t diagonal = 0, off_sum = 0;
        int previous_column = -1;
        for (size_t edge = (size_t)v[row_ptr + row];
             edge < (size_t)v[row_ptr + row + 1]; ++edge) {
            const int64_t column = v[columns + edge];
            const int64_t entry = v[entries + edge];
            if (column < 0 || column >= (int64_t)n || column <= previous_column ||
                entry == 0 || entry < -max_micro || entry > max_micro) return 0;
            previous_column = (int)column;
            if ((size_t)column == row) diagonal = entry;
            else off_sum += entry < 0 ? -entry : entry;
        }
        if (diagonal <= 0 || diagonal <= off_sum) return 0;
    }
    for (size_t row = 0; row < n; ++row) {
        for (size_t edge = (size_t)v[row_ptr + row];
             edge < (size_t)v[row_ptr + row + 1]; ++edge) {
            const size_t column = (size_t)v[columns + edge];
            const int64_t entry = v[entries + edge];
            int found = 0;
            for (size_t reverse = (size_t)v[row_ptr + column];
                 reverse < (size_t)v[row_ptr + column + 1]; ++reverse) {
                if ((size_t)v[columns + reverse] == row && v[entries + reverse] == entry) {
                    found = 1;
                    break;
                }
            }
            if (!found) return 0;
        }
    }
    *n_out = n;
    *outer_out = (size_t)v[1];
    *steps_out = (size_t)v[2];
    *nnz_out = nnz;
    return 1;
}

int64_t npb_cg_sparse_inverse_power(const int64_t *values, size_t length,
                                   uint8_t *output, size_t output_capacity) {
    size_t n, outer_count, cg_steps, nnz;
    if (!validate(values, length, &n, &outer_count, &cg_steps, &nnz)) return -1;
    const size_t output_bytes = outer_count * 16;
    if (output == NULL || output_capacity < output_bytes) return -2;

    double x[MAX_N], z[MAX_N], r[MAX_N], p[MAX_N], q[MAX_N], az[MAX_N];
    for (size_t i = 0; i < n; ++i) x[i] = 1.0;
    for (size_t outer = 0; outer < outer_count; ++outer) {
        double rhs_squared = 0.0;
        for (size_t i = 0; i < n; ++i) {
            z[i] = 0.0;
            r[i] = x[i];
            p[i] = x[i];
            rhs_squared += r[i] * r[i];
        }
        double residual_squared = rhs_squared;
        for (size_t step = 0; step < cg_steps && residual_squared > 0.0; ++step) {
            sparse_matvec(n, nnz, values, p, q);
            double denominator = 0.0;
            for (size_t i = 0; i < n; ++i) denominator += p[i] * q[i];
            if (!(denominator > 0.0) || !isfinite(denominator)) return -1;
            const double alpha = residual_squared / denominator;
            for (size_t i = 0; i < n; ++i) {
                z[i] += alpha * p[i];
                r[i] -= alpha * q[i];
            }
            double next_squared = 0.0;
            for (size_t i = 0; i < n; ++i) next_squared += r[i] * r[i];
            if (next_squared <= rhs_squared * 1.0e-28) {
                residual_squared = next_squared;
                break;
            }
            const double beta = next_squared / residual_squared;
            for (size_t i = 0; i < n; ++i) p[i] = r[i] + beta * p[i];
            residual_squared = next_squared;
        }
        sparse_matvec(n, nnz, values, z, az);
        double explicit_residual_squared = 0.0, x_dot_z = 0.0, z_squared = 0.0;
        for (size_t i = 0; i < n; ++i) {
            const double difference = x[i] - az[i];
            explicit_residual_squared += difference * difference;
            x_dot_z += x[i] * z[i];
            z_squared += z[i] * z[i];
        }
        if (!(x_dot_z > 0.0) || !(z_squared > 0.0) ||
            !isfinite(x_dot_z) || !isfinite(z_squared)) return -1;
        const double eigenvalue = (double)values[3] / scale_micro + 1.0 / x_dot_z;
        const double residual_norm = sqrt(explicit_residual_squared);
        if (!isfinite(eigenvalue) || !isfinite(residual_norm)) return -1;
        write_f64_le(output, outer * 16, eigenvalue);
        write_f64_le(output, outer * 16 + 8, residual_norm);
        const double z_norm = sqrt(z_squared);
        for (size_t i = 0; i < n; ++i) x[i] = z[i] / z_norm;
    }
    return (int64_t)output_bytes;
}
