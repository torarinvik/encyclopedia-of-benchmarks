module npb_cg_sparse_inverse_power;

const usz MAX_N = 32;
const usz MAX_OUTER = 8;
const usz MAX_STEPS = 25;
const long MAX_MICRO = 1000000000;
const double SCALE = 1000000.0;
extern fn double sqrt(double value);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn void sparse_matvec(usz n, usz nnz, long* v, double* vector, double* product) {
    usz row_ptr = 5, columns = row_ptr + n + 1, entries = columns + nnz;
    for (usz row = 0; row < n; row++) {
        double sum = 0.0;
        for (usz edge = (usz)v[row_ptr + row]; edge < (usz)v[row_ptr + row + 1]; edge++)
            sum += (double)v[entries + edge] / SCALE * vector[(usz)v[columns + edge]];
        product[row] = sum;
    }
}

fn bool valid(long* v, usz length, usz* n_out, usz* outer_out, usz* steps_out, usz* nnz_out) {
    if (v == null || length < 8 || v[0] < 1 || v[0] > (long)MAX_N ||
        v[1] < 1 || v[1] > (long)MAX_OUTER || v[2] < 1 || v[2] > (long)MAX_STEPS ||
        v[2] > v[0] || v[3] < -MAX_MICRO || v[3] > MAX_MICRO ||
        v[4] < v[0] || v[4] > 6 * v[0]) return false;
    usz n = (usz)v[0], nnz = (usz)v[4];
    if (length != n + 6 + 2 * nnz) return false;
    usz rp = 5, col = rp + n + 1, val = col + nnz;
    if (v[rp] != 0 || v[rp + n] != (long)nnz) return false;
    for (usz row = 0; row < n; row++) {
        long begin = v[rp + row], end = v[rp + row + 1];
        if (begin < 0 || begin >= end || end > (long)nnz) return false;
        long diagonal = 0, off_sum = 0, previous = -1;
        for (usz edge = (usz)begin; edge < (usz)end; edge++) {
            long column = v[col + edge], entry = v[val + edge];
            if (column < 0 || column >= (long)n || column <= previous || entry == 0 ||
                entry < -MAX_MICRO || entry > MAX_MICRO) return false;
            previous = column;
            if ((usz)column == row) diagonal = entry;
            else off_sum += entry < 0 ? -entry : entry;
        }
        if (diagonal <= 0 || diagonal <= off_sum) return false;
    }
    for (usz row = 0; row < n; row++) {
        for (usz edge = (usz)v[rp + row]; edge < (usz)v[rp + row + 1]; edge++) {
            usz column = (usz)v[col + edge];
            bool found = false;
            for (usz reverse = (usz)v[rp + column]; reverse < (usz)v[rp + column + 1]; reverse++) {
                if (v[col + reverse] == (long)row && v[val + reverse] == v[val + edge]) { found = true; break; }
            }
            if (!found) return false;
        }
    }
    *n_out = n; *outer_out = (usz)v[1]; *steps_out = (usz)v[2]; *nnz_out = nnz;
    return true;
}

fn long npb_cg_sparse_inverse_power(long* values, usz length, char* output, usz output_capacity)
        @export("npb_cg_sparse_inverse_power") {
    usz n, outer_count, steps, nnz;
    if (!valid(values, length, &n, &outer_count, &steps, &nnz)) return -1;
    usz output_bytes = outer_count * 16;
    if (output == null || output_capacity < output_bytes) return -2;
    double[MAX_N] x = {0}, z = {0}, r = {0}, p = {0}, q = {0}, az = {0};
    for (usz i = 0; i < n; i++) x[i] = 1.0;
    for (usz outer = 0; outer < outer_count; outer++) {
        double rhs2 = 0.0;
        for (usz i = 0; i < n; i++) { z[i] = 0.0; r[i] = x[i]; p[i] = x[i]; rhs2 += r[i] * r[i]; }
        double rr = rhs2;
        for (usz step = 0; step < steps && rr > 0.0; step++) {
            sparse_matvec(n, nnz, values, &p[0], &q[0]);
            double denominator = 0.0;
            for (usz i = 0; i < n; i++) denominator += p[i] * q[i];
            if (!(denominator > 0.0)) return -1;
            double alpha = rr / denominator;
            for (usz i = 0; i < n; i++) { z[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            double next = 0.0;
            for (usz i = 0; i < n; i++) next += r[i] * r[i];
            if (next <= rhs2 * 1.0e-28) { rr = next; break; }
            double beta = next / rr;
            for (usz i = 0; i < n; i++) p[i] = r[i] + beta * p[i];
            rr = next;
        }
        sparse_matvec(n, nnz, values, &z[0], &az[0]);
        double explicit2 = 0.0, dot = 0.0, z2 = 0.0;
        for (usz i = 0; i < n; i++) { double d = x[i] - az[i]; explicit2 += d*d; dot += x[i]*z[i]; z2 += z[i]*z[i]; }
        if (!(dot > 0.0) || !(z2 > 0.0)) return -1;
        double estimate = (double)values[3] / SCALE + 1.0 / dot;
        double residual_norm = sqrt(explicit2);
        write_f64_le(output, outer * 16, estimate);
        write_f64_le(output, outer * 16 + 8, residual_norm);
        double z_norm = sqrt(z2);
        for (usz i = 0; i < n; i++) x[i] = z[i] / z_norm;
    }
    return (long)output_bytes;
}
