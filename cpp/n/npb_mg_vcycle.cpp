/* Clean-room bounded implementation of the NASA NPB MG V-cycle specification. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int side = 4;
constexpr int cells = 64;
constexpr int max_sources = 8;
constexpr std::size_t max_input = 34;

int wrap_index(int value, int n) {
    if (value < 0) return value + n;
    if (value >= n) return value - n;
    return value;
}
std::size_t index3(int x, int y, int z, int n) {
    return static_cast<std::size_t>(x + n * (y + n * z));
}
void stencil(const double *src, double *dst, int n,
             double center, double face, double edge, double corner) {
    for (int z = 0; z < n; ++z) for (int y = 0; y < n; ++y) for (int x = 0; x < n; ++x) {
        const auto q = index3(x, y, z, n);
        double total = center * src[q];
        for (int dz = -1; dz <= 1; ++dz) for (int dy = -1; dy <= 1; ++dy) for (int dx = -1; dx <= 1; ++dx) {
            const int distance = std::abs(dx) + std::abs(dy) + std::abs(dz);
            if (distance == 0) continue;
            const double weight = distance == 1 ? face : distance == 2 ? edge : corner;
            const auto neighbor = index3(wrap_index(x + dx, n), wrap_index(y + dy, n), wrap_index(z + dz, n), n);
            total += weight * src[neighbor];
        }
        dst[q] = total;
    }
}
void restrict_grid(const double *fine, int n, double *coarse) {
    const int h = n / 2;
    for (int z = 0; z < h; ++z) for (int y = 0; y < h; ++y) for (int x = 0; x < h; ++x) {
        double total = 0.0;
        for (int dz = -1; dz <= 1; ++dz) for (int dy = -1; dy <= 1; ++dy) for (int dx = -1; dx <= 1; ++dx) {
            const double wx = dx == 0 ? 1.0 : 0.5;
            const double wy = dy == 0 ? 1.0 : 0.5;
            const double wz = dz == 0 ? 1.0 : 0.5;
            const auto q = index3(wrap_index(2*x + dx, n), wrap_index(2*y + dy, n), wrap_index(2*z + dz, n), n);
            total += wx * wy * wz * fine[q];
        }
        coarse[index3(x, y, z, h)] = 0.5 * total;
    }
}
void interpolate_grid(const double *coarse, int h, double *fine) {
    const int n = 2 * h;
    for (int z = 0; z < n; ++z) for (int y = 0; y < n; ++y) for (int x = 0; x < n; ++x) {
        const int bx = x/2, by = y/2, bz = z/2;
        const int nx = (x & 1) ? 2 : 1, ny = (y & 1) ? 2 : 1, nz = (z & 1) ? 2 : 1;
        double total = 0.0;
        for (int iz = 0; iz < nz; ++iz) for (int iy = 0; iy < ny; ++iy) for (int ix = 0; ix < nx; ++ix) {
            const double wx = (x & 1) ? 0.5 : 1.0;
            const double wy = (y & 1) ? 0.5 : 1.0;
            const double wz = (z & 1) ? 0.5 : 1.0;
            total += wx * wy * wz * coarse[index3((bx+ix)%h, (by+iy)%h, (bz+iz)%h, h)];
        }
        fine[index3(x, y, z, n)] = total;
    }
}
void vcycle(const double *rhs, int n, double *solution) {
    if (n == 2) { stencil(rhs, solution, n, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0); return; }
    const int h = n / 2;
    double coarse_rhs[cells]{}, coarse_solution[cells]{}, prolonged[cells]{};
    double applied[cells]{}, remaining[cells]{}, post[cells]{};
    restrict_grid(rhs, n, coarse_rhs);
    vcycle(coarse_rhs, h, coarse_solution);
    interpolate_grid(coarse_solution, h, prolonged);
    stencil(prolonged, applied, n, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
    const int count = n*n*n;
    for (int q = 0; q < count; ++q) remaining[q] = rhs[q] - applied[q];
    stencil(remaining, post, n, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0);
    for (int q = 0; q < count; ++q) solution[q] = prolonged[q] + post[q];
}
} // namespace

extern "C" std::int64_t npb_mg_vcycle(const double *input, std::size_t length,
                                       double *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const double iteration_value = input[0], count_value = input[1];
    if (!std::isfinite(iteration_value) || std::trunc(iteration_value) != iteration_value ||
        iteration_value < 1 || iteration_value > 4 || !std::isfinite(count_value) ||
        std::trunc(count_value) != count_value || count_value < 0 || count_value > max_sources) return -1;
    const int iterations = static_cast<int>(iteration_value), sources = static_cast<int>(count_value);
    if (length != 2 + 4 * static_cast<std::size_t>(sources)) return -1;
    double rhs[cells]{};
    bool seen[cells]{};
    for (int source = 0; source < sources; ++source) {
        const auto base = 2 + 4 * static_cast<std::size_t>(source);
        const double xv = input[base], yv = input[base+1], zv = input[base+2], value = input[base+3];
        if (!std::isfinite(xv) || std::trunc(xv) != xv || xv < 0 || xv >= side ||
            !std::isfinite(yv) || std::trunc(yv) != yv || yv < 0 || yv >= side ||
            !std::isfinite(zv) || std::trunc(zv) != zv || zv < 0 || zv >= side ||
            !std::isfinite(value) || value < -4 || value > 4) return -1;
        const auto q = index3(static_cast<int>(xv), static_cast<int>(yv), static_cast<int>(zv), side);
        if (seen[q]) return -1;
        seen[q] = true;
        rhs[q] = value;
    }
    if (output == nullptr || capacity < 1) return -2;
    double solution[cells]{}, applied[cells]{}, residual[cells]{}, correction[cells]{};
    for (int iteration = 0; iteration < iterations; ++iteration) {
        stencil(solution, applied, side, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
        for (int q = 0; q < cells; ++q) residual[q] = rhs[q] - applied[q];
        vcycle(residual, side, correction);
        for (int q = 0; q < cells; ++q) solution[q] += correction[q];
    }
    double checksum = 0.0;
    for (double value : solution) checksum += value;
    output[0] = checksum;
    return 1;
}
