#include <stddef.h>
#include <stdint.h>

#define VRM_MAX_SIDE 8
#define VRM_MAX_RAYS 16
#define VRM_MAX_SAMPLES 32
#define VRM_MAX_VOXELS (VRM_MAX_SIDE * VRM_MAX_SIDE * VRM_MAX_SIDE)
#define VRM_MAX_INPUT (3 + 2 * VRM_MAX_VOXELS + 6 * VRM_MAX_RAYS)
#define VRM_MAX_PARSEABLE (VRM_MAX_INPUT + 1)
#define VRM_MAX_LEVELS 4
#define VRM_Q8 INT64_C(256)
#define VRM_Q16 INT64_C(65536)
#define VRM_WEIGHT_DEN INT64_C(16777216)
#define VRM_ALPHA_DEN (INT64_C(255) * VRM_WEIGHT_DEN)
#define VRM_COLOR_DEN (INT64_C(255) * INT64_C(255) * VRM_WEIGHT_DEN)

static size_t voxel_index(int side, int x, int y, int z) {
    return ((size_t)z * (size_t)side + (size_t)y) * (size_t)side + (size_t)x;
}

static size_t mask_index(int level, int x, int y, int z) {
    return ((((size_t)level * VRM_MAX_SIDE + (size_t)z) * VRM_MAX_SIDE +
             (size_t)y) * VRM_MAX_SIDE + (size_t)x);
}

static int64_t round_half_up(int64_t numerator, int64_t denominator) {
    return (numerator + denominator / 2) / denominator;
}

static uint8_t to_byte(int64_t q16) {
    return (uint8_t)((q16 * 255 + VRM_Q16 / 2) / VRM_Q16);
}

static void interpolate(int side, const uint8_t *alpha, const uint8_t *gray,
                        int64_t xq, int64_t yq, int64_t zq,
                        int64_t *opacity_q16, int64_t *premul_gray_q16) {
    const int low[3] = {(int)(xq / VRM_Q8), (int)(yq / VRM_Q8), (int)(zq / VRM_Q8)};
    const int frac[3] = {(int)(xq % VRM_Q8), (int)(yq % VRM_Q8), (int)(zq % VRM_Q8)};
    const int high[3] = {
        low[0] + (low[0] + 1 < side),
        low[1] + (low[1] + 1 < side),
        low[2] + (low[2] + 1 < side)
    };
    int64_t opacity_sum = 0;
    int64_t premul_sum = 0;
    for (int dz = 0; dz < 2; ++dz) {
        const int z = dz ? high[2] : low[2];
        const int64_t wz = dz ? frac[2] : VRM_Q8 - frac[2];
        for (int dy = 0; dy < 2; ++dy) {
            const int y = dy ? high[1] : low[1];
            const int64_t wy = dy ? frac[1] : VRM_Q8 - frac[1];
            for (int dx = 0; dx < 2; ++dx) {
                const int x = dx ? high[0] : low[0];
                const int64_t wx = dx ? frac[0] : VRM_Q8 - frac[0];
                const size_t at = voxel_index(side, x, y, z);
                const int64_t weight = wx * wy * wz;
                opacity_sum += (int64_t)alpha[at] * weight;
                premul_sum += (int64_t)alpha[at] * (int64_t)gray[at] * weight;
            }
        }
    }
    *opacity_q16 = round_half_up(opacity_sum * VRM_Q16, VRM_ALPHA_DEN);
    *premul_gray_q16 = round_half_up(premul_sum * VRM_Q16, VRM_COLOR_DEN);
}

int64_t splash2_volrend_raymarch(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > VRM_MAX_PARSEABLE) return -1;
    const int64_t side_raw = input[0], ray_raw = input[1], samples_raw = input[2];
    if ((side_raw != 2 && side_raw != 4 && side_raw != 8) ||
        ray_raw < 1 || ray_raw > VRM_MAX_RAYS ||
        samples_raw < 1 || samples_raw > VRM_MAX_SAMPLES) return -1;
    const int side = (int)side_raw;
    const size_t ray_count = (size_t)ray_raw;
    const int sample_count = (int)samples_raw;
    const size_t voxel_count = (size_t)side * (size_t)side * (size_t)side;
    const size_t ray_start = 3 + 2 * voxel_count;
    if (length != ray_start + 6 * ray_count) return -1;

    uint8_t alpha[VRM_MAX_VOXELS] = {0};
    uint8_t gray[VRM_MAX_VOXELS] = {0};
    int32_t rays[VRM_MAX_RAYS][6] = {{0}};
    for (size_t voxel = 0; voxel < voxel_count; ++voxel) {
        const int64_t a = input[3 + 2 * voxel];
        const int64_t g = input[4 + 2 * voxel];
        if (a < 0 || a > 255 || g < 0 || g > 255) return -1;
        alpha[voxel] = (uint8_t)a;
        gray[voxel] = (uint8_t)g;
    }
    const int64_t coord_max = (side - 1) * VRM_Q8;
    for (size_t ray = 0; ray < ray_count; ++ray) {
        const size_t at = ray_start + 6 * ray;
        for (int axis = 0; axis < 3; ++axis) {
            const int64_t origin = input[at + (size_t)axis];
            const int64_t delta = input[at + (size_t)axis + 3];
            if (origin < 0 || origin > coord_max ||
                delta < -coord_max || delta > coord_max)
                return -1;
            rays[ray][axis] = (int32_t)origin;
            rays[ray][axis + 3] = (int32_t)delta;
        }
        if (sample_count > 1 && rays[ray][3] == 0 &&
            rays[ray][4] == 0 && rays[ray][5] == 0)
            return -1;
        for (int sample = 0; sample < sample_count; ++sample) {
            for (int axis = 0; axis < 3; ++axis) {
                const int64_t coordinate = (int64_t)rays[ray][axis] +
                    (int64_t)sample * rays[ray][axis + 3];
                if (coordinate < 0 || coordinate > coord_max) return -1;
            }
        }
    }

    const size_t output_bytes = 5 * ray_count;
    if (output == NULL) return -2;
    if (capacity < output_bytes) return -3;

    uint8_t support[VRM_MAX_LEVELS][VRM_MAX_SIDE][VRM_MAX_SIDE][VRM_MAX_SIDE] = {{{{0}}}};
    for (int z = 0; z < side; ++z) {
        for (int y = 0; y < side; ++y) {
            for (int x = 0; x < side; ++x) {
                uint8_t occupied = 0;
                for (int dz = 0; dz < 2; ++dz)
                    for (int dy = 0; dy < 2; ++dy)
                        for (int dx = 0; dx < 2; ++dx) {
                            const int nx = x + (x + 1 < side && dx);
                            const int ny = y + (y + 1 < side && dy);
                            const int nz = z + (z + 1 < side && dz);
                            occupied |= alpha[voxel_index(side, nx, ny, nz)] != 0;
                        }
                support[0][z][y][x] = occupied;
            }
        }
    }
    int levels = 0;
    for (int dimension = side; dimension > 1; dimension >>= 1) ++levels;
    for (int level = 1; level <= levels; ++level) {
        const int dimension = side >> level;
        for (int z = 0; z < dimension; ++z)
            for (int y = 0; y < dimension; ++y)
                for (int x = 0; x < dimension; ++x) {
                    uint8_t occupied = 0;
                    for (int dz = 0; dz < 2; ++dz)
                        for (int dy = 0; dy < 2; ++dy)
                            for (int dx = 0; dx < 2; ++dx)
                                occupied |= support[level - 1][2 * z + dz][2 * y + dy][2 * x + dx];
                    support[level][z][y][x] = occupied;
                }
    }

    for (size_t ray = 0; ray < ray_count; ++ray) {
        int64_t accumulated_alpha = 0, accumulated_gray = 0;
        int used = 0;
        for (int sample = 0; sample < sample_count; ++sample) {
            used = sample + 1;
            const int64_t xq = (int64_t)rays[ray][0] + (int64_t)sample * rays[ray][3];
            const int64_t yq = (int64_t)rays[ray][1] + (int64_t)sample * rays[ray][4];
            const int64_t zq = (int64_t)rays[ray][2] + (int64_t)sample * rays[ray][5];
            const int cell[3] = {(int)(xq / VRM_Q8), (int)(yq / VRM_Q8), (int)(zq / VRM_Q8)};
            int supported = 1;
            for (int level = levels; level >= 0; --level) {
                if (support[level][cell[2] >> level][cell[1] >> level][cell[0] >> level] == 0) {
                    supported = 0;
                    break;
                }
            }
            if (supported) {
                int64_t sample_alpha, sample_gray;
                interpolate(side, alpha, gray, xq, yq, zq, &sample_alpha, &sample_gray);
                const int64_t remaining = VRM_Q16 - accumulated_alpha;
                accumulated_alpha += round_half_up(remaining * sample_alpha, VRM_Q16);
                accumulated_gray += round_half_up(remaining * sample_gray, VRM_Q16);
                if (accumulated_alpha > VRM_Q16) accumulated_alpha = VRM_Q16;
                if (accumulated_gray > VRM_Q16) accumulated_gray = VRM_Q16;
                if (accumulated_alpha == VRM_Q16) break;
            }
        }
        const size_t out = 5 * ray;
        const uint8_t value = to_byte(accumulated_gray);
        output[out] = value;
        output[out + 1] = value;
        output[out + 2] = value;
        output[out + 3] = to_byte(accumulated_alpha);
        output[out + 4] = (uint8_t)used;
    }
    return (int64_t)output_bytes;
}
