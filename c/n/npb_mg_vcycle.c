/* Clean-room bounded implementation of the NASA NPB MG V-cycle specification. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define SIDE 4
#define CELLS 64
#define MAX_SOURCES 8
#define MAX_INPUT 34

static int wrap_index(int value, int side) {
    if (value < 0) return value + side;
    if (value >= side) return value - side;
    return value;
}

static size_t grid_index(int x, int y, int z, int side) {
    return (size_t)x + (size_t)side * ((size_t)y + (size_t)side * (size_t)z);
}

static void apply_stencil(const double *source, double *target, int side,
                          double center, double face, double edge, double corner) {
    for (int z = 0; z < side; ++z) {
        for (int y = 0; y < side; ++y) {
            for (int x = 0; x < side; ++x) {
                const size_t q = grid_index(x, y, z, side);
                double total = center * source[q];
                for (int dz = -1; dz <= 1; ++dz) {
                    for (int dy = -1; dy <= 1; ++dy) {
                        for (int dx = -1; dx <= 1; ++dx) {
                            const int distance = (dx < 0 ? -dx : dx) +
                                                 (dy < 0 ? -dy : dy) +
                                                 (dz < 0 ? -dz : dz);
                            if (distance == 0) continue;
                            const double weight = distance == 1 ? face :
                                                  distance == 2 ? edge : corner;
                            const size_t neighbor = grid_index(
                                wrap_index(x + dx, side), wrap_index(y + dy, side),
                                wrap_index(z + dz, side), side);
                            total += weight * source[neighbor];
                        }
                    }
                }
                target[q] = total;
            }
        }
    }
}

static void restrict_grid(const double *fine, int side, double *coarse) {
    const int half = side / 2;
    for (int z = 0; z < half; ++z) {
        for (int y = 0; y < half; ++y) {
            for (int x = 0; x < half; ++x) {
                double total = 0.0;
                for (int dz = -1; dz <= 1; ++dz) {
                    const double wz = dz == 0 ? 1.0 : 0.5;
                    for (int dy = -1; dy <= 1; ++dy) {
                        const double wy = dy == 0 ? 1.0 : 0.5;
                        for (int dx = -1; dx <= 1; ++dx) {
                            const double wx = dx == 0 ? 1.0 : 0.5;
                            const size_t q = grid_index(
                                wrap_index(2 * x + dx, side),
                                wrap_index(2 * y + dy, side),
                                wrap_index(2 * z + dz, side), side);
                            total += wx * wy * wz * fine[q];
                        }
                    }
                }
                coarse[grid_index(x, y, z, half)] = 0.5 * total;
            }
        }
    }
}

static void interpolate_grid(const double *coarse, int half, double *fine) {
    const int side = 2 * half;
    for (int z = 0; z < side; ++z) {
        for (int y = 0; y < side; ++y) {
            for (int x = 0; x < side; ++x) {
                const int bx = x / 2, by = y / 2, bz = z / 2;
                const int nx = (x & 1) ? 2 : 1;
                const int ny = (y & 1) ? 2 : 1;
                const int nz = (z & 1) ? 2 : 1;
                double total = 0.0;
                for (int iz = 0; iz < nz; ++iz) {
                    const int cz = (bz + iz) % half;
                    const double wz = (z & 1) ? 0.5 : 1.0;
                    for (int iy = 0; iy < ny; ++iy) {
                        const int cy = (by + iy) % half;
                        const double wy = (y & 1) ? 0.5 : 1.0;
                        for (int ix = 0; ix < nx; ++ix) {
                            const int cx = (bx + ix) % half;
                            const double wx = (x & 1) ? 0.5 : 1.0;
                            total += wx * wy * wz * coarse[grid_index(cx, cy, cz, half)];
                        }
                    }
                }
                fine[grid_index(x, y, z, side)] = total;
            }
        }
    }
}

static void vcycle(const double *rhs, int side, double *solution) {
    if (side == 2) {
        apply_stencil(rhs, solution, side, -3.0 / 8.0, 1.0 / 32.0,
                      -1.0 / 64.0, 0.0);
        return;
    }
    const int half = side / 2;
    double coarse_rhs[CELLS] = {0.0};
    double coarse_solution[CELLS] = {0.0};
    double prolonged[CELLS] = {0.0};
    double applied[CELLS] = {0.0};
    double remaining[CELLS] = {0.0};
    double post_smooth[CELLS] = {0.0};
    restrict_grid(rhs, side, coarse_rhs);
    vcycle(coarse_rhs, half, coarse_solution);
    interpolate_grid(coarse_solution, half, prolonged);
    apply_stencil(prolonged, applied, side, -8.0 / 3.0, 0.0,
                  1.0 / 6.0, 1.0 / 12.0);
    const size_t cells = (size_t)side * (size_t)side * (size_t)side;
    for (size_t q = 0; q < cells; ++q) remaining[q] = rhs[q] - applied[q];
    apply_stencil(remaining, post_smooth, side, -3.0 / 8.0, 1.0 / 32.0,
                  -1.0 / 64.0, 0.0);
    for (size_t q = 0; q < cells; ++q) solution[q] = prolonged[q] + post_smooth[q];
}

int64_t npb_mg_vcycle(const double *input, size_t length,
                      double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const double iterations_value = input[0];
    const double count_value = input[1];
    if (!isfinite(iterations_value) || trunc(iterations_value) != iterations_value ||
        iterations_value < 1.0 || iterations_value > 4.0 ||
        !isfinite(count_value) || trunc(count_value) != count_value ||
        count_value < 0.0 || count_value > MAX_SOURCES) return -1;
    const int iterations = (int)iterations_value;
    const int count = (int)count_value;
    if (length != 2 + 4 * (size_t)count) return -1;

    double rhs[CELLS] = {0.0};
    unsigned char seen[CELLS] = {0};
    for (int source = 0; source < count; ++source) {
        const size_t base = 2 + 4 * (size_t)source;
        const double xv = input[base], yv = input[base + 1], zv = input[base + 2];
        const double value = input[base + 3];
        if (!isfinite(xv) || trunc(xv) != xv || xv < 0.0 || xv >= SIDE ||
            !isfinite(yv) || trunc(yv) != yv || yv < 0.0 || yv >= SIDE ||
            !isfinite(zv) || trunc(zv) != zv || zv < 0.0 || zv >= SIDE ||
            !isfinite(value) || value < -4.0 || value > 4.0) return -1;
        const size_t q = grid_index((int)xv, (int)yv, (int)zv, SIDE);
        if (seen[q]) return -1;
        seen[q] = 1;
        rhs[q] = value;
    }
    if (output == NULL || capacity < 1) return -2;

    double solution[CELLS] = {0.0};
    double applied[CELLS] = {0.0};
    double residual[CELLS] = {0.0};
    double correction[CELLS] = {0.0};
    for (int iteration = 0; iteration < iterations; ++iteration) {
        apply_stencil(solution, applied, SIDE, -8.0 / 3.0, 0.0,
                      1.0 / 6.0, 1.0 / 12.0);
        for (size_t q = 0; q < CELLS; ++q) residual[q] = rhs[q] - applied[q];
        vcycle(residual, SIDE, correction);
        for (size_t q = 0; q < CELLS; ++q) solution[q] += correction[q];
    }
    double checksum = 0.0;
    for (size_t q = 0; q < CELLS; ++q) checksum += solution[q];
    output[0] = checksum;
    return 1;
}
