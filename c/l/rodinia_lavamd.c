/* Rodinia LavaMD bounded home-box force/potential kernel; see package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define LMD_MAX_PARTICLES 4
#define LMD_SCALE 1000000.0
#define LMD_BIAS INT64_C(1000000000000)

static int64_t lmd_round(double value) {
    const double scaled = value * LMD_SCALE;
    return scaled < 0.0 ? -(int64_t)floor(-scaled + 0.5) : (int64_t)floor(scaled + 0.5);
}

int64_t rodinia_lavamd(const int64_t *input, size_t length) {
    if (input == NULL || length < 12 || length > 42) return -1;
    if (input[0] < 1 || input[0] > LMD_MAX_PARTICLES || input[1] < 1 || input[1] > LMD_MAX_PARTICLES) return -1;
    const size_t home_n = (size_t)input[0], neighbor_n = (size_t)input[1];
    if (length != 2 + 5 * (home_n + neighbor_n)) return -1;
    double particles[2][LMD_MAX_PARTICLES][5];
    const size_t counts[2] = {home_n, neighbor_n};
    size_t cursor = 2;
    for (size_t box = 0; box < 2; ++box) for (size_t p = 0; p < counts[box]; ++p) {
        for (size_t component = 0; component < 5; ++component) {
            const int64_t raw = input[cursor++];
            if (raw < 0 || raw > 1000000) return -1;
            particles[box][p][component] = (double)raw / LMD_SCALE;
        }
    }
    double total = 0.0;
    for (size_t i = 0; i < home_n; ++i) {
        double force_v = 0.0, force_x = 0.0, force_y = 0.0, force_z = 0.0;
        const double *a = particles[0][i];
        for (size_t box = 0; box < 2; ++box) for (size_t j = 0; j < counts[box]; ++j) {
            const double *b = particles[box][j];
            const double dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
            const double r2 = a[0] + b[0] - dot;
            const double vij = exp(-(0.5 * r2));
            const double fs = 2.0 * vij;
            const double dx = a[1] - b[1], dy = a[2] - b[2], dz = a[3] - b[3];
            const double fxij = fs * dx, fyij = fs * dy, fzij = fs * dz;
            force_v += b[4] * vij;
            force_x += b[4] * fxij;
            force_y += b[4] * fyij;
            force_z += b[4] * fzij;
        }
        total += (double)(i + 1) * ((force_v + force_x) + force_y + force_z);
    }
    return LMD_BIAS + lmd_round(total);
}
