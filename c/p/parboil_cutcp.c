#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_DIM = 4, MAX_ATOMS = 4, MAX_INPUT = 25, MAX_GRID = 64, MAX_OUTPUT = 256 };
static const float CELL_LENGTH = 4.0f;
static const float INV_CELL_LENGTH = 0.25f;

typedef struct { float x, y, z, q; } atom_t;

static float decode_component(int64_t raw) { return (float)raw / 1000000.0f; }

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    uint32_t bits = (uint32_t)value;
    output[offset] = (uint8_t)bits;
    output[offset + 1] = (uint8_t)(bits >> 8);
    output[offset + 2] = (uint8_t)(bits >> 16);
    output[offset + 3] = (uint8_t)(bits >> 24);
}

int64_t parboil_cutcp(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 13 || input_length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_DIM || input[1] < 2 || input[1] > MAX_DIM
            || input[2] < 2 || input[2] > MAX_DIM || input[3] < 1 || input[3] > MAX_ATOMS) return -1;
    int nx = (int)input[0], ny = (int)input[1], nz = (int)input[2];
    int natoms = (int)input[3];
    if (input_length != 9u + 4u * (size_t)natoms) return -1;
    const int64_t xlo_raw = input[4], ylo_raw = input[5], zlo_raw = input[6];
    const int64_t spacing_raw = input[7], cutoff_raw = input[8];
    if (xlo_raw < -16000000 || xlo_raw > 16000000
            || ylo_raw < -16000000 || ylo_raw > 16000000
            || zlo_raw < -16000000 || zlo_raw > 16000000
            || xlo_raw % 1000000 != 0 || ylo_raw % 1000000 != 0 || zlo_raw % 1000000 != 0
            || spacing_raw < 1000000 || spacing_raw > 4000000 || spacing_raw % 1000000 != 0
            || cutoff_raw < 250000 || cutoff_raw > 4000000) return -1;
    atom_t atoms[MAX_ATOMS];
    for (int n = 0; n < natoms; ++n) {
        const size_t offset = 9u + 4u * (size_t)n;
        const int64_t ix = input[offset], iy = input[offset + 1], iz = input[offset + 2];
        const int64_t charge_raw = input[offset + 3];
        if (ix < 0 || ix >= nx - 1 || iy < 0 || iy >= ny - 1 || iz < 0 || iz >= nz - 1
                || charge_raw < -1000000 || charge_raw > 1000000) return -1;
    }

    const size_t points = (size_t)nx * (size_t)ny * (size_t)nz;
    const size_t output_bytes = 4u * points;
    if (output == NULL || output_capacity < output_bytes) return -2;

    const float xlo = decode_component(xlo_raw);
    const float ylo = decode_component(ylo_raw);
    const float zlo = decode_component(zlo_raw);
    const float spacing = decode_component(spacing_raw);
    const float cutoff = decode_component(cutoff_raw);
    const float half_spacing = spacing * 0.5f;
    for (int n = 0; n < natoms; ++n) {
        const size_t offset = 9u + 4u * (size_t)n;
        const int ix = (int)input[offset], iy = (int)input[offset + 1], iz = (int)input[offset + 2];
        atoms[n].x = xlo + ((float)ix * spacing + half_spacing);
        atoms[n].y = ylo + ((float)iy * spacing + half_spacing);
        atoms[n].z = zlo + ((float)iz * spacing + half_spacing);
        atoms[n].q = decode_component(input[offset + 3]);
    }

    float min_x = atoms[0].x, max_x = atoms[0].x;
    float min_y = atoms[0].y, max_y = atoms[0].y;
    float min_z = atoms[0].z, max_z = atoms[0].z;
    for (int n = 1; n < natoms; ++n) {
        if (atoms[n].x < min_x) min_x = atoms[n].x;
        if (atoms[n].x > max_x) max_x = atoms[n].x;
        if (atoms[n].y < min_y) min_y = atoms[n].y;
        if (atoms[n].y > max_y) max_y = atoms[n].y;
        if (atoms[n].z < min_z) min_z = atoms[n].z;
        if (atoms[n].z > max_z) max_z = atoms[n].z;
    }
    const int nx_cell = (int)floorf((max_x - min_x) * INV_CELL_LENGTH) + 1;
    const int ny_cell = (int)floorf((max_y - min_y) * INV_CELL_LENGTH) + 1;
    const int nz_cell = (int)floorf((max_z - min_z) * INV_CELL_LENGTH) + 1;
    const int cell_count = nx_cell * ny_cell * nz_cell;
    int first[MAX_GRID], next[MAX_ATOMS];
    for (int cell = 0; cell < cell_count; ++cell) first[cell] = -1;
    for (int n = 0; n < natoms; ++n) next[n] = -1;
    for (int n = 0; n < natoms; ++n) {
        if (atoms[n].q == 0.0f) continue;
        const int i = (int)floorf((atoms[n].x - min_x) * INV_CELL_LENGTH);
        const int j = (int)floorf((atoms[n].y - min_y) * INV_CELL_LENGTH);
        const int k = (int)floorf((atoms[n].z - min_z) * INV_CELL_LENGTH);
        const int cell = (k * ny_cell + j) * nx_cell + i;
        next[n] = first[cell];
        first[cell] = n;
    }

    const float cutoff_squared = cutoff * cutoff;
    const float inv_cutoff_squared = 1.0f / cutoff_squared;
    const float inv_spacing = 1.0f / spacing;
    const int radius = (int)ceilf(cutoff * inv_spacing) - 1;
    float grid[MAX_GRID] = {0.0f};
    for (int cell = 0; cell < cell_count; ++cell) {
        for (int n = first[cell]; n != -1; n = next[n]) {
            const float x = atoms[n].x - xlo;
            const float y = atoms[n].y - ylo;
            const float z = atoms[n].z - zlo;
            const float q = atoms[n].q;
            const int ic = (int)(x * inv_spacing);
            const int jc = (int)(y * inv_spacing);
            const int kc = (int)(z * inv_spacing);
            int ia = ic - radius, ib = ic + radius + 1;
            int ja = jc - radius, jb = jc + radius + 1;
            int ka = kc - radius, kb = kc + radius + 1;
            if (ia < 0) ia = 0;
            if (ib >= nx) ib = nx - 1;
            if (ja < 0) ja = 0;
            if (jb >= ny) jb = ny - 1;
            if (ka < 0) ka = 0;
            if (kb >= nz) kb = nz - 1;

            const float xstart = (float)ia * spacing - x;
            const float ystart = (float)ja * spacing - y;
            float dz = (float)ka * spacing - z;
            for (int k = ka; k <= kb; ++k, dz += spacing) {
                const int koff = k * ny;
                const float dz2 = dz * dz;
                float dy = ystart;
                for (int j = ja; j <= jb; ++j, dy += spacing) {
                    const int jkoff = (koff + j) * nx;
                    const float dydz2 = dy * dy + dz2;
                    if (dydz2 >= cutoff_squared) continue;
                    float dx = xstart;
                    for (int i = ia; i <= ib; ++i, dx += spacing) {
                        const float r2 = dx * dx + dydz2;
                        if (r2 >= cutoff_squared) continue;
                        const float s = 1.0f - r2 * inv_cutoff_squared;
                        float e = q * (1.0f / sqrtf(r2)) * s * s;
                        grid[jkoff + i] += e;
                    }
                }
            }
        }
    }
    for (size_t point = 0; point < points; ++point)
        write_i32_le(output, 4u * point, (int32_t)roundf(grid[point] * 1000.0f));
    return (int64_t)output_bytes;
}
