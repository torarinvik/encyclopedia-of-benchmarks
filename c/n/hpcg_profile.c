#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_N = 32, MAX_COARSE = 16, MAX_STEPS = 12, MAX_ROW_NNZ = 6 };
static const int64_t MAX_MICRO = INT64_C(1000000000);
static const double SCALE = 1000000.0;

static size_t rp_at(size_t n) { (void)n; return 3; }
static size_t col_at(size_t n) { return 4 + n; }
static size_t val_at(size_t n, size_t nnz) { return 4 + n + nnz; }
static size_t rhs_at(size_t n, size_t nnz) { return val_at(n, nnz) + nnz; }

static int validate(const int64_t *v, size_t length, size_t *n_out, size_t *steps_out,
                    size_t *nnz_out, double *diagonal) {
    if (v == NULL || length < 8 || length > 452 || v[0] < 1 || v[0] > MAX_N ||
        v[1] < 1 || v[1] > MAX_STEPS || v[1] > v[0] || v[2] < v[0] ||
        v[2] > 6 * v[0]) return 0;
    const size_t n = (size_t)v[0], steps = (size_t)v[1], nnz = (size_t)v[2];
    if (length != 4 + 2 * n + 2 * nnz) return 0;
    const size_t rp = rp_at(n), col = col_at(n), val = val_at(n, nnz), rhs = rhs_at(n, nnz);
    if (v[rp] != 0 || v[rp + n] != (int64_t)nnz) return 0;
    for (size_t row = 0; row < n; ++row) {
        const int64_t begin = v[rp + row], end = v[rp + row + 1];
        if (begin < 0 || begin >= end || end > (int64_t)nnz || end - begin > MAX_ROW_NNZ) return 0;
        int64_t diag = 0, off_sum = 0, previous = -1;
        for (size_t edge = (size_t)begin; edge < (size_t)end; ++edge) {
            const int64_t c = v[col + edge], a = v[val + edge];
            if (c < 0 || c >= (int64_t)n || c <= previous || a == 0 ||
                a < -MAX_MICRO || a > MAX_MICRO) return 0;
            previous = c;
            if ((size_t)c == row) diag = a;
            else off_sum += a < 0 ? -a : a;
        }
        if (diag <= 0 || diag <= off_sum) return 0;
        diagonal[row] = (double)diag / SCALE;
        if (v[rhs + row] < -MAX_MICRO || v[rhs + row] > MAX_MICRO) return 0;
    }
    for (size_t row = 0; row < n; ++row) {
        for (size_t edge = (size_t)v[rp + row]; edge < (size_t)v[rp + row + 1]; ++edge) {
            const size_t c = (size_t)v[col + edge];
            int found = 0;
            for (size_t reverse = (size_t)v[rp + c]; reverse < (size_t)v[rp + c + 1]; ++reverse)
                if ((size_t)v[col + reverse] == row && v[val + reverse] == v[val + edge]) { found = 1; break; }
            if (!found) return 0;
        }
    }
    *n_out = n; *steps_out = steps; *nnz_out = nnz;
    return 1;
}

static void matvec(size_t n, size_t nnz, const int64_t *v, const double *x, double *y) {
    const size_t rp = rp_at(n), col = col_at(n), val = val_at(n, nnz);
    for (size_t row = 0; row < n; ++row) {
        double sum = 0.0;
        for (size_t edge = (size_t)v[rp + row]; edge < (size_t)v[rp + row + 1]; ++edge)
            sum += (double)v[val + edge] / SCALE * x[(size_t)v[col + edge]];
        y[row] = sum;
    }
}

static int coarse_solve(size_t n, size_t nnz, const int64_t *v,
                        const double *coarse_rhs, double *solution) {
    const size_t cn = (n + 1) / 2, rp = rp_at(n), col = col_at(n), val = val_at(n, nnz);
    double a[MAX_COARSE][MAX_COARSE] = {{0}}, l[MAX_COARSE][MAX_COARSE] = {{0}};
    for (size_t row = 0; row < n; ++row)
        for (size_t edge = (size_t)v[rp + row]; edge < (size_t)v[rp + row + 1]; ++edge)
            a[row / 2][(size_t)v[col + edge] / 2] += (double)v[val + edge] / SCALE;
    for (size_t i = 0; i < cn; ++i) {
        for (size_t j = 0; j <= i; ++j) {
            double value = a[i][j];
            for (size_t k = 0; k < j; ++k) value -= l[i][k] * l[j][k];
            if (i == j) {
                if (!(value > 0.0) || !isfinite(value)) return 0;
                l[i][j] = sqrt(value);
            } else l[i][j] = value / l[j][j];
        }
    }
    double y[MAX_COARSE] = {0};
    for (size_t i = 0; i < cn; ++i) {
        double value = coarse_rhs[i];
        for (size_t j = 0; j < i; ++j) value -= l[i][j] * y[j];
        y[i] = value / l[i][i];
    }
    for (size_t ii = cn; ii-- > 0;) {
        double value = y[ii];
        for (size_t j = ii + 1; j < cn; ++j) value -= l[j][ii] * solution[j];
        solution[ii] = value / l[ii][ii];
    }
    return 1;
}

static int precondition(size_t n, size_t nnz, const int64_t *v, const double *diag,
                        const double *r, double *z) {
    const size_t rp = rp_at(n), col = col_at(n), val = val_at(n, nnz);
    double y[MAX_N] = {0}, pre_residual[MAX_N] = {0}, middle[MAX_N] = {0};
    double post_residual[MAX_N] = {0}, correction[MAX_N] = {0};
    double coarse_rhs[MAX_COARSE] = {0}, coarse_x[MAX_COARSE] = {0}, product[MAX_N] = {0};
    for (size_t row = 0; row < n; ++row) {
        double value = r[row];
        for (size_t edge = (size_t)v[rp + row]; edge < (size_t)v[rp + row + 1]; ++edge) {
            const size_t c = (size_t)v[col + edge];
            if (c < row) value -= (double)v[val + edge] / SCALE * y[c];
        }
        y[row] = value / diag[row];
    }
    matvec(n, nnz, v, y, product);
    for (size_t row = 0; row < n; ++row) {
        pre_residual[row] = r[row] - product[row];
        coarse_rhs[row / 2] += pre_residual[row];
    }
    if (!coarse_solve(n, nnz, v, coarse_rhs, coarse_x)) return 0;
    for (size_t row = 0; row < n; ++row) middle[row] = y[row] + coarse_x[row / 2];
    matvec(n, nnz, v, middle, product);
    for (size_t row = 0; row < n; ++row) post_residual[row] = r[row] - product[row];
    for (size_t ii = n; ii-- > 0;) {
        double value = post_residual[ii];
        for (size_t edge = (size_t)v[rp + ii]; edge < (size_t)v[rp + ii + 1]; ++edge) {
            const size_t c = (size_t)v[col + edge];
            if (c > ii) value -= (double)v[val + edge] / SCALE * correction[c];
        }
        correction[ii] = value / diag[ii];
    }
    for (size_t row = 0; row < n; ++row) z[row] = middle[row] + correction[row];
    return 1;
}

static void write_f64_le(uint8_t *out, size_t offset, double value) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t hpcg_profile(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    size_t n, steps, nnz;
    double diagonal[MAX_N] = {0};
    if (!validate(values, length, &n, &steps, &nnz, diagonal)) return -1;
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    const size_t rhs = rhs_at(n, nnz);
    double b[MAX_N] = {0}, x[MAX_N] = {0}, r[MAX_N] = {0}, z[MAX_N] = {0};
    double p[MAX_N] = {0}, q[MAX_N] = {0}, ax[MAX_N] = {0};
    double b2 = 0.0;
    for (size_t i = 0; i < n; ++i) { b[i] = (double)values[rhs + i] / SCALE; r[i] = b[i]; b2 += b[i] * b[i]; }
    if (b2 > 0.0) {
        if (!precondition(n, nnz, values, diagonal, r, z)) return -1;
        memcpy(p, z, n * sizeof(double));
        double rho = 0.0;
        for (size_t i = 0; i < n; ++i) rho += r[i] * z[i];
        if (!(rho > 0.0) || !isfinite(rho)) return -1;
        for (size_t step = 0; step < steps; ++step) {
            matvec(n, nnz, values, p, q);
            double curvature = 0.0;
            for (size_t i = 0; i < n; ++i) curvature += p[i] * q[i];
            if (!(curvature > 0.0) || !isfinite(curvature)) return -1;
            const double alpha = rho / curvature;
            for (size_t i = 0; i < n; ++i) { x[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            double r2 = 0.0;
            for (size_t i = 0; i < n; ++i) r2 += r[i] * r[i];
            if (r2 <= b2 * 1.0e-28) break;
            double next_z[MAX_N] = {0};
            if (!precondition(n, nnz, values, diagonal, r, next_z)) return -1;
            double next_rho = 0.0;
            for (size_t i = 0; i < n; ++i) next_rho += r[i] * next_z[i];
            if (!(next_rho > 0.0) || !isfinite(next_rho)) return -1;
            const double beta = next_rho / rho;
            for (size_t i = 0; i < n; ++i) { z[i] = next_z[i]; p[i] = z[i] + beta * p[i]; }
            rho = next_rho;
        }
    }
    matvec(n, nnz, values, x, ax);
    double residual2 = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const double difference = b[i] - ax[i];
        residual2 += difference * difference;
        if (!isfinite(x[i])) return -1;
        write_f64_le(output, 8 * i, x[i]);
    }
    const double norm = sqrt(residual2);
    if (!isfinite(norm)) return -1;
    write_f64_le(output, 8 * n, norm);
    return (int64_t)output_bytes;
}
