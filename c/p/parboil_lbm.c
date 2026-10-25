#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define Q 19
#define CELLS 27
#define WIDTH 3
#define HALO_WIDTH 5
#define INPUT_COUNT 19

static const int dx[Q]  = {0,0,0,1,-1,0,0, 1,-1,1,-1, 0,0,0,0, 1,1,-1,-1};
static const int dy[Q]  = {0,1,-1,0,0,0,0, 1,1,-1,-1, 1,1,-1,-1, 0,0,0,0};
static const int dz[Q]  = {0,0,0,0,0,1,-1, 0,0,0,0, 1,-1,1,-1, 1,-1,1,-1};
static const int opposite[Q] = {0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15};

static int cell_index(int x, int y, int z) { return x + WIDTH * y + WIDTH * WIDTH * z; }
static int halo_index(int x, int y, int z, int q) {
    return (((z + 1) * HALO_WIDTH + (y + 1)) * HALO_WIDTH + (x + 1)) * Q + q;
}

static float initial_weight(int q) {
    if (q == 0) return (float)(1.0 / 3.0);
    if (q <= 6) return (float)(1.0 / 18.0);
    return (float)(1.0 / 36.0);
}

static float axis_factor(float u, int positive, float u2) {
    float product = 4.5f * u;
    product = positive ? product + 3.0f : product - 3.0f;
    product = u * product;
    product = 1.0f + product;
    return product - u2;
}

static float diagonal_factor(float cu, float u2) {
    float product = 4.5f * cu;
    product = product + 3.0f;
    product = cu * product;
    product = 1.0f + product;
    return product - u2;
}

static float collide(float source, float rho, float factor, double weight) {
    const float omega = 1.95f;
    float base = (1.0f - omega) * source;
    double equilibrium = weight * (double)omega;
    equilibrium = equilibrium * (double)rho;
    equilibrium = equilibrium * (double)factor;
    return (float)((double)base + equilibrium);
}

static void collide_cell(const float *f, float *post) {
    float rho = f[0];
    rho = rho + f[1]; rho = rho + f[2]; rho = rho + f[3]; rho = rho + f[4];
    rho = rho + f[5]; rho = rho + f[6]; rho = rho + f[7]; rho = rho + f[8];
    rho = rho + f[9]; rho = rho + f[10]; rho = rho + f[11]; rho = rho + f[12];
    rho = rho + f[13]; rho = rho + f[14]; rho = rho + f[15]; rho = rho + f[16];
    rho = rho + f[17]; rho = rho + f[18];

    float ux = f[3]; ux = ux - f[4]; ux = ux + f[7]; ux = ux - f[8];
    ux = ux + f[9]; ux = ux - f[10]; ux = ux + f[15]; ux = ux + f[16];
    ux = ux - f[17]; ux = ux - f[18];
    float uy = f[1]; uy = uy - f[2]; uy = uy + f[7]; uy = uy + f[8];
    uy = uy - f[9]; uy = uy - f[10]; uy = uy + f[11]; uy = uy + f[12];
    uy = uy - f[13]; uy = uy - f[14];
    float uz = f[5]; uz = uz - f[6]; uz = uz + f[11]; uz = uz - f[12];
    uz = uz + f[13]; uz = uz - f[14]; uz = uz + f[15]; uz = uz - f[16];
    uz = uz + f[17]; uz = uz - f[18];
    ux = ux / rho; uy = uy / rho; uz = uz / rho;

    float u2 = ux * ux;
    u2 = u2 + uy * uy;
    u2 = u2 + uz * uz;
    u2 = 1.5f * u2;
    float rest = 1.0f - u2;
    post[0] = collide(f[0], rho, rest, 1.0 / 3.0);
    post[1] = collide(f[1], rho, axis_factor(uy, 1, u2), 1.0 / 18.0);
    post[2] = collide(f[2], rho, axis_factor(uy, 0, u2), 1.0 / 18.0);
    post[3] = collide(f[3], rho, axis_factor(ux, 1, u2), 1.0 / 18.0);
    post[4] = collide(f[4], rho, axis_factor(ux, 0, u2), 1.0 / 18.0);
    post[5] = collide(f[5], rho, axis_factor(uz, 1, u2), 1.0 / 18.0);
    post[6] = collide(f[6], rho, axis_factor(uz, 0, u2), 1.0 / 18.0);

    float cu = ux + uy; post[7] = collide(f[7], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -ux + uy; post[8] = collide(f[8], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = ux - uy; post[9] = collide(f[9], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -ux - uy; post[10] = collide(f[10], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = uy + uz; post[11] = collide(f[11], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = uy - uz; post[12] = collide(f[12], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -uy + uz; post[13] = collide(f[13], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -uy - uz; post[14] = collide(f[14], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = ux + uz; post[15] = collide(f[15], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = ux - uz; post[16] = collide(f[16], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -ux + uz; post[17] = collide(f[17], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
    cu = -ux - uz; post[18] = collide(f[18], rho, diagonal_factor(cu, u2), 1.0 / 36.0);
}

int64_t parboil_lbm(const int64_t *values, size_t length) {
    if (values == NULL || length != INPUT_COUNT) return -1;
    int nonzero = 0;
    for (int q = 0; q < Q; ++q) {
        if (values[q] < 0 || values[q] > 100000) return -1;
        if (values[q] != 0) nonzero = 1;
    }
    if (!nonzero) return -1;

    float source[CELLS][Q];
    float destination[HALO_WIDTH * HALO_WIDTH * HALO_WIDTH * Q] = {0};
    for (int z = 0; z < WIDTH; ++z) for (int y = 0; y < WIDTH; ++y) for (int x = 0; x < WIDTH; ++x) {
        int cell = cell_index(x, y, z);
        for (int q = 0; q < Q; ++q) {
            source[cell][q] = initial_weight(q);
            destination[halo_index(x, y, z, q)] = initial_weight(q);
        }
    }
    for (int q = 0; q < Q; ++q) source[cell_index(1, 1, 1)][q] = (float)values[q] / 1000000.0f;

    for (int z = 0; z < WIDTH; ++z) for (int y = 0; y < WIDTH; ++y) for (int x = 0; x < WIDTH; ++x) {
        int cell = cell_index(x, y, z);
        int obstacle = x == 0 || x == 2 || y == 0 || y == 2 || z == 0 || z == 2;
        float post[Q];
        if (!obstacle) collide_cell(source[cell], post);
        for (int q = 0; q < Q; ++q) {
            int target_x = x + dx[q], target_y = y + dy[q], target_z = z + dz[q];
            float outgoing = obstacle ? source[cell][opposite[q]] : post[q];
            destination[halo_index(target_x, target_y, target_z, q)] = outgoing;
        }
    }

    int64_t checksum = 0;
    for (int z = 0; z < WIDTH; ++z) for (int y = 0; y < WIDTH; ++y) for (int x = 0; x < WIDTH; ++x) {
        int cell = cell_index(x, y, z);
        for (int q = 0; q < Q; ++q) {
            float scaled = destination[halo_index(x, y, z, q)] * 1000000.0f;
            int64_t fixed = (int64_t)roundf(scaled);
            checksum += (int64_t)(cell + 1) * fixed;
        }
    }
    return checksum;
}
