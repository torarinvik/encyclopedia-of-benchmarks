module hpcg_profile;

const usz MAX_N = 32;
const usz MAX_COARSE = 16;
const usz MAX_STEPS = 12;
const long MAX_MICRO = 1000000000;
const double SCALE = 1000000.0;
extern fn double sqrt(double value);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz i = 0; i < 8; i++) output[offset + i] = (char)(bits >> (8 * i));
}

fn bool valid(long* v, usz length, usz* n_out, usz* steps_out, usz* nnz_out, double* diag) {
    if (v == null || length < 8 || length > 452 || v[0] < 1 || v[0] > (long)MAX_N ||
        v[1] < 1 || v[1] > (long)MAX_STEPS || v[1] > v[0] || v[2] < v[0] || v[2] > 6 * v[0]) return false;
    usz n = (usz)v[0], steps = (usz)v[1], nnz = (usz)v[2];
    if (length != 4 + 2 * n + 2 * nnz) return false;
    usz rp = 3, col = 4 + n, val = col + nnz, rhs = val + nnz;
    if (v[rp] != 0 || v[rp + n] != (long)nnz) return false;
    for (usz row = 0; row < n; row++) {
        long begin = v[rp + row], end = v[rp + row + 1];
        if (begin < 0 || begin >= end || end > (long)nnz || end - begin > 6) return false;
        long d = 0, off = 0, previous = -1;
        for (usz edge = (usz)begin; edge < (usz)end; edge++) {
            long c = v[col + edge], a = v[val + edge];
            if (c < 0 || c >= (long)n || c <= previous || a == 0 || a < -MAX_MICRO || a > MAX_MICRO) return false;
            previous = c;
            if ((usz)c == row) d = a; else off += a < 0 ? -a : a;
        }
        if (d <= 0 || d <= off || v[rhs + row] < -MAX_MICRO || v[rhs + row] > MAX_MICRO) return false;
        diag[row] = (double)d / SCALE;
    }
    for (usz row = 0; row < n; row++) for (usz edge = (usz)v[rp + row]; edge < (usz)v[rp + row + 1]; edge++) {
        usz c = (usz)v[col + edge];
        bool found = false;
        for (usz rev = (usz)v[rp + c]; rev < (usz)v[rp + c + 1]; rev++)
            if ((usz)v[col + rev] == row && v[val + rev] == v[val + edge]) { found = true; break; }
        if (!found) return false;
    }
    *n_out = n; *steps_out = steps; *nnz_out = nnz;
    return true;
}

fn void matvec(long* v, usz n, usz nnz, double* x, double* y) {
    usz col = 4 + n, val = col + nnz;
    for (usz row = 0; row < n; row++) {
        double sum = 0.0;
        for (usz edge = (usz)v[3 + row]; edge < (usz)v[4 + row]; edge++) sum += (double)v[val + edge] / SCALE * x[(usz)v[col + edge]];
        y[row] = sum;
    }
}

fn bool coarse_solve(long* v, usz n, usz nnz, double* rhs, double* result) {
    usz cn = (n + 1) / 2, col = 4 + n, val = col + nnz;
    double[MAX_COARSE * MAX_COARSE] a = {0}, l = {0};
    for (usz row = 0; row < n; row++) for (usz edge = (usz)v[3 + row]; edge < (usz)v[4 + row]; edge++)
        a[(row / 2) * MAX_COARSE + (usz)v[col + edge] / 2] += (double)v[val + edge] / SCALE;
    for (usz i = 0; i < cn; i++) for (usz j = 0; j <= i; j++) {
        double value = a[i * MAX_COARSE + j];
        for (usz k = 0; k < j; k++) value -= l[i * MAX_COARSE + k] * l[j * MAX_COARSE + k];
        if (i == j) { if (value <= 0.0) return false; l[i * MAX_COARSE + j] = sqrt(value); }
        else l[i * MAX_COARSE + j] = value / l[j * MAX_COARSE + j];
    }
    double[MAX_COARSE] y = {0};
    for (usz i = 0; i < cn; i++) { double t = rhs[i]; for (usz j = 0; j < i; j++) t -= l[i * MAX_COARSE + j] * y[j]; y[i] = t / l[i * MAX_COARSE + i]; }
    for (usz ii = cn; ii > 0; ii--) { usz i = ii - 1; double t = y[i]; for (usz j = i + 1; j < cn; j++) t -= l[j * MAX_COARSE + i] * result[j]; result[i] = t / l[i * MAX_COARSE + i]; }
    return true;
}

fn bool precondition(long* v, usz n, usz nnz, double* d, double* r, double* z) {
    usz col = 4 + n, val = col + nnz;
    double[MAX_N] pre = {0}, product = {0}, middle = {0}, post_r = {0}, post = {0};
    double[MAX_COARSE] crhs = {0}, cx = {0};
    for (usz row = 0; row < n; row++) {
        double t = r[row];
        for (usz edge = (usz)v[3 + row]; edge < (usz)v[4 + row]; edge++) { usz c = (usz)v[col + edge]; if (c < row) t -= (double)v[val + edge] / SCALE * pre[c]; }
        pre[row] = t / d[row];
    }
    matvec(v, n, nnz, &pre[0], &product[0]);
    for (usz row = 0; row < n; row++) crhs[row / 2] += r[row] - product[row];
    if (!coarse_solve(v, n, nnz, &crhs[0], &cx[0])) return false;
    for (usz row = 0; row < n; row++) middle[row] = pre[row] + cx[row / 2];
    matvec(v, n, nnz, &middle[0], &product[0]);
    for (usz row = 0; row < n; row++) post_r[row] = r[row] - product[row];
    for (usz ii = n; ii > 0; ii--) {
        usz row = ii - 1; double t = post_r[row];
        for (usz edge = (usz)v[3 + row]; edge < (usz)v[4 + row]; edge++) { usz c = (usz)v[col + edge]; if (c > row) t -= (double)v[val + edge] / SCALE * post[c]; }
        post[row] = t / d[row];
    }
    for (usz row = 0; row < n; row++) z[row] = middle[row] + post[row];
    return true;
}

fn long hpcg_profile(long* values, usz length, char* output, usz output_capacity) @export("hpcg_profile") {
    usz n, steps, nnz; double[MAX_N] diag = {0};
    if (!valid(values, length, &n, &steps, &nnz, &diag[0])) return -1;
    usz bytes = 8 * (n + 1);
    if (output == null || output_capacity < bytes) return -2;
    usz rhs = 4 + n + 2 * nnz;
    double[MAX_N] b = {0}, x = {0}, r = {0}, z = {0}, p = {0}, q = {0}, ax = {0};
    double b2 = 0.0;
    for (usz i = 0; i < n; i++) { b[i] = (double)values[rhs + i] / SCALE; r[i] = b[i]; b2 += b[i] * b[i]; }
    if (b2 > 0.0) {
        if (!precondition(values, n, nnz, &diag[0], &r[0], &z[0])) return -1;
        for (usz i = 0; i < n; i++) p[i] = z[i];
        double rho = 0.0; for (usz i = 0; i < n; i++) rho += r[i] * z[i];
        if (rho <= 0.0) return -1;
        for (usz step = 0; step < steps; step++) {
            matvec(values, n, nnz, &p[0], &q[0]);
            double curvature = 0.0; for (usz i = 0; i < n; i++) curvature += p[i] * q[i];
            if (curvature <= 0.0) return -1;
            double alpha = rho / curvature;
            for (usz i = 0; i < n; i++) { x[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            double r2 = 0.0; for (usz i = 0; i < n; i++) r2 += r[i] * r[i];
            if (r2 <= b2 * 1.0e-28) break;
            double[MAX_N] nz = {0};
            if (!precondition(values, n, nnz, &diag[0], &r[0], &nz[0])) return -1;
            double next_rho = 0.0; for (usz i = 0; i < n; i++) next_rho += r[i] * nz[i];
            if (next_rho <= 0.0) return -1;
            double beta = next_rho / rho;
            for (usz i = 0; i < n; i++) { z[i] = nz[i]; p[i] = z[i] + beta * p[i]; }
            rho = next_rho;
        }
    }
    matvec(values, n, nnz, &x[0], &ax[0]);
    double r2 = 0.0;
    for (usz i = 0; i < n; i++) { double e = b[i] - ax[i]; r2 += e * e; write_f64_le(output, 8 * i, x[i]); }
    write_f64_le(output, 8 * n, sqrt(r2));
    return (long)bytes;
}
