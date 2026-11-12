module npb_lu_block_ssor;

extern fn double sqrt(double value);

const usz MAX_POINTS = 32;
const long MAX_MICRO = 1000000000;
const double SCALE = 1000000.0;

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn bool solve5(double* d, double* rhs, double* result) {
    double[25] a = {};
    double[5] b = {};
    for (usz i = 0; i < 25; i++) a[i] = d[i];
    for (usz i = 0; i < 5; i++) b[i] = rhs[i];
    for (usz pivot = 0; pivot < 5; pivot++) {
        double divisor = a[pivot * 5 + pivot];
        if (!(divisor > 0.0)) return false;
        for (usz row = pivot + 1; row < 5; row++) {
            double factor = a[row * 5 + pivot] / divisor;
            for (usz col = pivot + 1; col < 5; col++) a[row * 5 + col] -= factor * a[pivot * 5 + col];
            b[row] -= factor * b[pivot];
        }
    }
    for (usz back = 0; back < 5; back++) {
        usz row = 4 - back;
        double tail = 0.0;
        for (usz col = row + 1; col < 5; col++) tail += a[row * 5 + col] * result[col];
        result[row] = (b[row] - tail) / a[row * 5 + row];
    }
    return true;
}

fn void apply(usz nx, usz ny, usz nz, double* d, double* c, double* x, double* out) {
    usz points = nx * ny * nz, nxy = nx * ny;
    for (usz point = 0; point < points; point++) {
        usz ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
        for (usz row = 0; row < 5; row++) {
            double total = 0.0;
            for (usz col = 0; col < 5; col++) total += d[row * 5 + col] * x[point * 5 + col];
            if (ix > 0) total += c[0] * x[(point - 1) * 5 + row];
            if (ix + 1 < nx) total += c[0] * x[(point + 1) * 5 + row];
            if (iy > 0) total += c[1] * x[(point - nx) * 5 + row];
            if (iy + 1 < ny) total += c[1] * x[(point + nx) * 5 + row];
            if (iz > 0) total += c[2] * x[(point - nxy) * 5 + row];
            if (iz + 1 < nz) total += c[2] * x[(point + nxy) * 5 + row];
            out[point * 5 + row] = total;
        }
    }
}

fn bool valid(long* v, usz length, usz* nx_out, usz* ny_out, usz* nz_out, usz* sweeps_out) {
    if (v == null || length < 42 || length > 352 || v[0] < 1 || v[0] > 4 ||
        v[1] < 1 || v[1] > 4 || v[2] < 1 || v[2] > 4 || v[3] < 1 || v[3] > 8) return false;
    usz nx = (usz)v[0], ny = (usz)v[1], nz = (usz)v[2], points = nx * ny * nz;
    if (points > MAX_POINTS || length != 32 + 10 * points) return false;
    for (usz i = 4; i < length; i++) if (v[i] < -MAX_MICRO || v[i] > MAX_MICRO) return false;
    usz[3] extent = {nx, ny, nz};
    for (usz row = 0; row < 5; row++) {
        long diagonal = v[4 + row * 5 + row], off_sum = 0;
        for (usz col = 0; col < 5; col++) {
            long value = v[4 + row * 5 + col];
            if (value != v[4 + col * 5 + row]) return false;
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        for (usz axis = 0; axis < 3; axis++) {
            if (extent[axis] > 1) { long c = v[29 + axis]; off_sum += 2 * (c < 0 ? -c : c); }
        }
        if (diagonal <= 0 || diagonal <= off_sum) return false;
    }
    *nx_out = nx; *ny_out = ny; *nz_out = nz; *sweeps_out = (usz)v[3];
    return true;
}

fn long npb_lu_block_ssor(long* values, usz length, char* output, usz output_capacity)
        @export("npb_lu_block_ssor") {
    usz nx, ny, nz, sweeps;
    if (!valid(values, length, &nx, &ny, &nz, &sweeps)) return -1;
    usz points = nx * ny * nz, count = points * 5, output_bytes = 8 * (sweeps + count);
    if (output == null || output_capacity < output_bytes) return -2;
    double[25] d = {};
    double[3] c = {};
    for (usz i = 0; i < 25; i++) d[i] = (double)values[4 + i] / SCALE;
    for (usz i = 0; i < 3; i++) c[i] = (double)values[29 + i] / SCALE;
    double[MAX_POINTS * 5] x = {}, rhs = {}, applied = {}, residual = {}, forward = {}, correction = {};
    for (usz i = 0; i < count; i++) {
        rhs[i] = (double)values[32 + i] / SCALE;
        x[i] = (double)values[32 + count + i] / SCALE;
    }
    usz nxy = nx * ny;
    for (usz sweep = 0; sweep < sweeps; sweep++) {
        apply(nx, ny, nz, &d[0], &c[0], &x[0], &applied[0]);
        for (usz i = 0; i < count; i++) residual[i] = rhs[i] - applied[i];
        for (usz point = 0; point < points; point++) {
            usz ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double[5] local = {}, solved = {};
            for (usz row = 0; row < 5; row++) local[row] = residual[point * 5 + row];
            if (ix > 0) for (usz row = 0; row < 5; row++) local[row] -= c[0] * forward[(point - 1) * 5 + row];
            if (iy > 0) for (usz row = 0; row < 5; row++) local[row] -= c[1] * forward[(point - nx) * 5 + row];
            if (iz > 0) for (usz row = 0; row < 5; row++) local[row] -= c[2] * forward[(point - nxy) * 5 + row];
            if (!solve5(&d[0], &local[0], &solved[0])) return -1;
            for (usz row = 0; row < 5; row++) forward[point * 5 + row] = solved[row];
        }
        for (usz back = 0; back < points; back++) {
            usz point = points - 1 - back, ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double[5] local = {}, solved = {};
            for (usz row = 0; row < 5; row++)
                for (usz col = 0; col < 5; col++) local[row] += d[row * 5 + col] * forward[point * 5 + col];
            if (ix + 1 < nx) for (usz row = 0; row < 5; row++) local[row] -= c[0] * correction[(point + 1) * 5 + row];
            if (iy + 1 < ny) for (usz row = 0; row < 5; row++) local[row] -= c[1] * correction[(point + nx) * 5 + row];
            if (iz + 1 < nz) for (usz row = 0; row < 5; row++) local[row] -= c[2] * correction[(point + nxy) * 5 + row];
            if (!solve5(&d[0], &local[0], &solved[0])) return -1;
            for (usz row = 0; row < 5; row++) correction[point * 5 + row] = solved[row];
        }
        for (usz i = 0; i < count; i++) x[i] += correction[i];
        apply(nx, ny, nz, &d[0], &c[0], &x[0], &applied[0]);
        double norm2 = 0.0;
        for (usz i = 0; i < count; i++) { double r = rhs[i] - applied[i]; norm2 += r * r; }
        write_f64_le(output, sweep * 8, sqrt(norm2));
    }
    for (usz i = 0; i < count; i++) write_f64_le(output, (sweeps + i) * 8, x[i]);
    return (long)output_bytes;
}
