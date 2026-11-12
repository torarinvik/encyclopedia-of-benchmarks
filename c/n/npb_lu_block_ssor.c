#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_POINTS = 32, MAX_AXIS = 4, MAX_SWEEPS = 8, COMPONENTS = 5 };
static const int64_t MAX_MICRO = INT64_C(1000000000);
static const double SCALE = 1000000.0;

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int solve5(const double d[25], const double rhs[5], double result[5]) {
    double a[25], b[5];
    memcpy(a, d, sizeof(a));
    memcpy(b, rhs, sizeof(b));
    for (size_t pivot = 0; pivot < 5; ++pivot) {
        double divisor = a[pivot * 5 + pivot];
        if (!(divisor > 0.0) || !isfinite(divisor)) return 0;
        for (size_t row = pivot + 1; row < 5; ++row) {
            double factor = a[row * 5 + pivot] / divisor;
            for (size_t column = pivot + 1; column < 5; ++column)
                a[row * 5 + column] -= factor * a[pivot * 5 + column];
            b[row] -= factor * b[pivot];
        }
    }
    for (int row = 4; row >= 0; --row) {
        double tail = 0.0;
        for (size_t column = (size_t)row + 1; column < 5; ++column)
            tail += a[(size_t)row * 5 + column] * result[column];
        result[row] = (b[row] - tail) / a[(size_t)row * 5 + (size_t)row];
    }
    return 1;
}

static void apply_operator(size_t nx, size_t ny, size_t nz, const double d[25],
                           const double coupling[3], const double *x, double *result) {
    const size_t points = nx * ny * nz, nxy = nx * ny;
    for (size_t point = 0; point < points; ++point) {
        size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
        const size_t previous[3] = {
            ix ? point - 1 : points, iy ? point - nx : points, iz ? point - nxy : points
        };
        const size_t following[3] = {
            ix + 1 < nx ? point + 1 : points,
            iy + 1 < ny ? point + nx : points,
            iz + 1 < nz ? point + nxy : points
        };
        for (size_t row = 0; row < 5; ++row) {
            double total = 0.0;
            for (size_t column = 0; column < 5; ++column)
                total += d[row * 5 + column] * x[point * 5 + column];
            for (size_t axis = 0; axis < 3; ++axis) {
                if (previous[axis] < points) total += coupling[axis] * x[previous[axis] * 5 + row];
                if (following[axis] < points) total += coupling[axis] * x[following[axis] * 5 + row];
            }
            result[point * 5 + row] = total;
        }
    }
}

static int valid(const int64_t *v, size_t length, size_t *nx_out, size_t *ny_out,
                 size_t *nz_out, size_t *sweeps_out) {
    if (v == NULL || length < 42 || length > 32 + 10 * MAX_POINTS) return 0;
    if (v[0] < 1 || v[0] > MAX_AXIS || v[1] < 1 || v[1] > MAX_AXIS ||
        v[2] < 1 || v[2] > MAX_AXIS || v[3] < 1 || v[3] > MAX_SWEEPS) return 0;
    size_t nx = (size_t)v[0], ny = (size_t)v[1], nz = (size_t)v[2];
    size_t points = nx * ny * nz;
    if (points > MAX_POINTS || length != 32 + 10 * points) return 0;
    for (size_t index = 4; index < length; ++index)
        if (v[index] < -MAX_MICRO || v[index] > MAX_MICRO) return 0;
    for (size_t row = 0; row < 5; ++row) {
        int64_t diagonal = v[4 + row * 5 + row];
        int64_t off_sum = 0;
        for (size_t column = 0; column < 5; ++column) {
            int64_t value = v[4 + row * 5 + column];
            if (value != v[4 + column * 5 + row]) return 0;
            if (column != row) off_sum += value < 0 ? -value : value;
        }
        const size_t extents[3] = { nx, ny, nz };
        for (size_t axis = 0; axis < 3; ++axis) {
            if (extents[axis] > 1) {
                int64_t value = v[29 + axis];
                off_sum += value < 0 ? -2 * value : 2 * value;
            }
        }
        if (diagonal <= 0 || diagonal <= off_sum) return 0;
    }
    *nx_out = nx; *ny_out = ny; *nz_out = nz; *sweeps_out = (size_t)v[3];
    return 1;
}

int64_t npb_lu_block_ssor(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity) {
    size_t nx, ny, nz, sweeps;
    if (!valid(values, length, &nx, &ny, &nz, &sweeps)) return -1;
    const size_t points = nx * ny * nz, count = points * 5;
    const size_t output_bytes = 8 * (sweeps + count);
    if (output == NULL || output_capacity < output_bytes) return -2;

    double d[25], coupling[3];
    for (size_t i = 0; i < 25; ++i) d[i] = (double)values[4 + i] / SCALE;
    for (size_t axis = 0; axis < 3; ++axis) coupling[axis] = (double)values[29 + axis] / SCALE;
    double x[MAX_POINTS * 5], rhs[MAX_POINTS * 5], residual[MAX_POINTS * 5];
    double applied[MAX_POINTS * 5], forward[MAX_POINTS * 5], correction[MAX_POINTS * 5];
    for (size_t i = 0; i < count; ++i) {
        rhs[i] = (double)values[32 + i] / SCALE;
        x[i] = (double)values[32 + count + i] / SCALE;
    }
    const size_t nxy = nx * ny;
    for (size_t sweep = 0; sweep < sweeps; ++sweep) {
        apply_operator(nx, ny, nz, d, coupling, x, applied);
        for (size_t i = 0; i < count; ++i) residual[i] = rhs[i] - applied[i];
        for (size_t point = 0; point < points; ++point) {
            size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double local[5], solved[5];
            for (size_t row = 0; row < 5; ++row) local[row] = residual[point * 5 + row];
            if (ix) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[0] * forward[(point - 1) * 5 + row];
            if (iy) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[1] * forward[(point - nx) * 5 + row];
            if (iz) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[2] * forward[(point - nxy) * 5 + row];
            if (!solve5(d, local, solved)) return -1;
            for (size_t row = 0; row < 5; ++row) forward[point * 5 + row] = solved[row];
        }
        for (size_t point = points; point-- > 0;) {
            size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double local[5] = {0.0}, solved[5];
            for (size_t row = 0; row < 5; ++row)
                for (size_t column = 0; column < 5; ++column)
                    local[row] += d[row * 5 + column] * forward[point * 5 + column];
            if (ix + 1 < nx) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[0] * correction[(point + 1) * 5 + row];
            if (iy + 1 < ny) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[1] * correction[(point + nx) * 5 + row];
            if (iz + 1 < nz) for (size_t row = 0; row < 5; ++row) local[row] -= coupling[2] * correction[(point + nxy) * 5 + row];
            if (!solve5(d, local, solved)) return -1;
            for (size_t row = 0; row < 5; ++row) correction[point * 5 + row] = solved[row];
        }
        for (size_t i = 0; i < count; ++i) x[i] += correction[i];
        apply_operator(nx, ny, nz, d, coupling, x, applied);
        double residual_squared = 0.0;
        for (size_t i = 0; i < count; ++i) {
            double difference = rhs[i] - applied[i];
            residual_squared += difference * difference;
        }
        write_f64_le(output, sweep * 8, sqrt(residual_squared));
    }
    for (size_t i = 0; i < count; ++i) write_f64_le(output, (sweeps + i) * 8, x[i]);
    return (int64_t)output_bytes;
}
