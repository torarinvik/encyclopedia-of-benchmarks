#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_points = 32, max_axis = 4, max_sweeps = 8;
constexpr std::int64_t max_micro = 1000000000;
constexpr double scale = 1000000.0;

void write_le(std::uint8_t* out, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

bool solve5(const double* d, const double* rhs, double* result) {
    double a[25], b[5];
    std::memcpy(a, d, sizeof(a));
    std::memcpy(b, rhs, sizeof(b));
    for (std::size_t pivot = 0; pivot < 5; ++pivot) {
        const double divisor = a[pivot * 5 + pivot];
        if (!(divisor > 0.0) || !std::isfinite(divisor)) return false;
        for (std::size_t row = pivot + 1; row < 5; ++row) {
            const double factor = a[row * 5 + pivot] / divisor;
            for (std::size_t column = pivot + 1; column < 5; ++column)
                a[row * 5 + column] -= factor * a[pivot * 5 + column];
            b[row] -= factor * b[pivot];
        }
    }
    for (int row = 4; row >= 0; --row) {
        double tail = 0.0;
        for (std::size_t column = static_cast<std::size_t>(row) + 1; column < 5; ++column)
            tail += a[static_cast<std::size_t>(row) * 5 + column] * result[column];
        result[row] = (b[row] - tail) / a[static_cast<std::size_t>(row) * 5 + static_cast<std::size_t>(row)];
    }
    return true;
}

bool valid(const std::int64_t* v, std::size_t length,
           std::size_t& nx, std::size_t& ny, std::size_t& nz, std::size_t& sweeps) {
    if (v == nullptr || length < 42 || length > 32 + 10 * max_points) return false;
    if (v[0] < 1 || v[0] > static_cast<std::int64_t>(max_axis) ||
        v[1] < 1 || v[1] > static_cast<std::int64_t>(max_axis) ||
        v[2] < 1 || v[2] > static_cast<std::int64_t>(max_axis) ||
        v[3] < 1 || v[3] > static_cast<std::int64_t>(max_sweeps)) return false;
    nx = static_cast<std::size_t>(v[0]); ny = static_cast<std::size_t>(v[1]); nz = static_cast<std::size_t>(v[2]);
    sweeps = static_cast<std::size_t>(v[3]);
    const std::size_t points = nx * ny * nz;
    if (points > max_points || length != 32 + 10 * points) return false;
    for (std::size_t index = 4; index < length; ++index)
        if (v[index] < -max_micro || v[index] > max_micro) return false;
    const std::size_t extent[3] = {nx, ny, nz};
    for (std::size_t row = 0; row < 5; ++row) {
        const std::int64_t diagonal = v[4 + row * 5 + row];
        std::int64_t off_sum = 0;
        for (std::size_t column = 0; column < 5; ++column) {
            const auto value = v[4 + row * 5 + column];
            if (value != v[4 + column * 5 + row]) return false;
            if (column != row) off_sum += value < 0 ? -value : value;
        }
        for (std::size_t axis = 0; axis < 3; ++axis)
            if (extent[axis] > 1) off_sum += 2 * (v[29 + axis] < 0 ? -v[29 + axis] : v[29 + axis]);
        if (diagonal <= 0 || diagonal <= off_sum) return false;
    }
    return true;
}

void apply(std::size_t nx, std::size_t ny, std::size_t nz, const double* d,
           const double* coupling, const double* x, double* out) {
    const std::size_t points = nx * ny * nz, nxy = nx * ny;
    for (std::size_t point = 0; point < points; ++point) {
        const std::size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
        const std::size_t previous[3] = {ix ? point - 1 : points, iy ? point - nx : points, iz ? point - nxy : points};
        const std::size_t following[3] = {ix + 1 < nx ? point + 1 : points,
                                          iy + 1 < ny ? point + nx : points,
                                          iz + 1 < nz ? point + nxy : points};
        for (std::size_t row = 0; row < 5; ++row) {
            double total = 0.0;
            for (std::size_t col = 0; col < 5; ++col) total += d[row * 5 + col] * x[point * 5 + col];
            for (std::size_t axis = 0; axis < 3; ++axis) {
                if (previous[axis] < points) total += coupling[axis] * x[previous[axis] * 5 + row];
                if (following[axis] < points) total += coupling[axis] * x[following[axis] * 5 + row];
            }
            out[point * 5 + row] = total;
        }
    }
}
} // namespace

extern "C" std::int64_t npb_lu_block_ssor(const std::int64_t* values, std::size_t length,
                                            std::uint8_t* output, std::size_t output_capacity) {
    std::size_t nx, ny, nz, sweeps;
    if (!valid(values, length, nx, ny, nz, sweeps)) return -1;
    const std::size_t points = nx * ny * nz, count = points * 5;
    const std::size_t output_bytes = 8 * (sweeps + count);
    if (output == nullptr || output_capacity < output_bytes) return -2;
    double d[25], coupling[3];
    for (std::size_t i = 0; i < 25; ++i) d[i] = static_cast<double>(values[4 + i]) / scale;
    for (std::size_t a = 0; a < 3; ++a) coupling[a] = static_cast<double>(values[29 + a]) / scale;
    double x[max_points * 5]{}, rhs[max_points * 5]{}, applied[max_points * 5]{};
    double residual[max_points * 5]{}, forward[max_points * 5]{}, correction[max_points * 5]{};
    for (std::size_t i = 0; i < count; ++i) {
        rhs[i] = static_cast<double>(values[32 + i]) / scale;
        x[i] = static_cast<double>(values[32 + count + i]) / scale;
    }
    const std::size_t nxy = nx * ny;
    for (std::size_t sweep = 0; sweep < sweeps; ++sweep) {
        apply(nx, ny, nz, d, coupling, x, applied);
        for (std::size_t i = 0; i < count; ++i) residual[i] = rhs[i] - applied[i];
        for (std::size_t point = 0; point < points; ++point) {
            const std::size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double local[5], solved[5]{};
            for (std::size_t row = 0; row < 5; ++row) local[row] = residual[point * 5 + row];
            if (ix) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[0] * forward[(point - 1) * 5 + row];
            if (iy) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[1] * forward[(point - nx) * 5 + row];
            if (iz) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[2] * forward[(point - nxy) * 5 + row];
            if (!solve5(d, local, solved)) return -1;
            for (std::size_t row = 0; row < 5; ++row) forward[point * 5 + row] = solved[row];
        }
        for (std::size_t point = points; point-- > 0;) {
            const std::size_t ix = point % nx, iy = (point / nx) % ny, iz = point / nxy;
            double local[5]{}, solved[5]{};
            for (std::size_t row = 0; row < 5; ++row)
                for (std::size_t col = 0; col < 5; ++col) local[row] += d[row * 5 + col] * forward[point * 5 + col];
            if (ix + 1 < nx) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[0] * correction[(point + 1) * 5 + row];
            if (iy + 1 < ny) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[1] * correction[(point + nx) * 5 + row];
            if (iz + 1 < nz) for (std::size_t row = 0; row < 5; ++row) local[row] -= coupling[2] * correction[(point + nxy) * 5 + row];
            if (!solve5(d, local, solved)) return -1;
            for (std::size_t row = 0; row < 5; ++row) correction[point * 5 + row] = solved[row];
        }
        for (std::size_t i = 0; i < count; ++i) x[i] += correction[i];
        apply(nx, ny, nz, d, coupling, x, applied);
        double norm2 = 0.0;
        for (std::size_t i = 0; i < count; ++i) { const double r = rhs[i] - applied[i]; norm2 += r * r; }
        write_le(output, sweep * 8, std::sqrt(norm2));
    }
    for (std::size_t i = 0; i < count; ++i) write_le(output, (sweeps + i) * 8, x[i]);
    return static_cast<std::int64_t>(output_bytes);
}
