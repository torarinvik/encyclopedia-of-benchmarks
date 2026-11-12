#include <stddef.h>
#include <stdint.h>

enum { MAX_MOLECULES = 64, MAX_GRID_SIDE = 8, MAX_CUTOFF = 4,
       MAX_CELLS = 512, MAX_INPUT_LENGTH = 4 + 4 * MAX_MOLECULES };
#define SCALE INT64_C(1000000)

static int64_t trunc_div_i64(int64_t numerator, int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t water_spatial(const int64_t *input, size_t length,
                      uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0], grid_value = input[1], cutoff_value = input[2];
    if (count_value < 0 || count_value > MAX_MOLECULES
            || grid_value < 1 || grid_value > MAX_GRID_SIDE
            || cutoff_value < 1 || cutoff_value > MAX_CUTOFF) return -1;
    const size_t count = (size_t)count_value;
    const int grid = (int)grid_value, cutoff = (int)cutoff_value;
    if (length != 3 + 4 * count) return -1;
    const int extent = grid * cutoff;
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 3 + 4 * i;
        if (input[base] < 0 || input[base] >= extent
                || input[base + 1] < 0 || input[base + 1] >= extent
                || input[base + 2] < 0 || input[base + 2] >= extent
                || input[base + 3] < -4 || input[base + 3] > 4) return -1;
    }
    const size_t output_bytes = 8 * (3 * count + 2);
    if (!output || capacity < output_bytes) return -2;

    int64_t head[MAX_CELLS], next[MAX_MOLECULES];
    int64_t force_x[MAX_MOLECULES] = {0};
    int64_t force_y[MAX_MOLECULES] = {0};
    int64_t force_z[MAX_MOLECULES] = {0};
    for (size_t cell = 0; cell < MAX_CELLS; ++cell) head[cell] = -1;
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 3 + 4 * i;
        const int cx = (int)(input[base] / cutoff);
        const int cy = (int)(input[base + 1] / cutoff);
        const int cz = (int)(input[base + 2] / cutoff);
        const int cell = cx + grid * (cy + grid * cz);
        next[i] = head[cell];
        head[cell] = (int64_t)i;
    }

    int64_t total_energy = 0, accepted_pairs = 0;
    const int64_t cutoff_squared = (int64_t)cutoff * cutoff;
    for (size_t i = 0; i < count; ++i) {
        const size_t base_i = 3 + 4 * i;
        const int cx = (int)(input[base_i] / cutoff);
        const int cy = (int)(input[base_i + 1] / cutoff);
        const int cz = (int)(input[base_i + 2] / cutoff);
        for (int oz = -1; oz <= 1; ++oz) {
            const int nz = cz + oz;
            if (nz < 0 || nz >= grid) continue;
            for (int oy = -1; oy <= 1; ++oy) {
                const int ny = cy + oy;
                if (ny < 0 || ny >= grid) continue;
                for (int ox = -1; ox <= 1; ++ox) {
                    const int nx = cx + ox;
                    if (nx < 0 || nx >= grid) continue;
                    const int cell = nx + grid * (ny + grid * nz);
                    for (int64_t candidate = head[cell]; candidate >= 0; candidate = next[candidate]) {
                        const size_t j = (size_t)candidate;
                        if (j <= i) continue;
                        const size_t base_j = 3 + 4 * j;
                        const int64_t dx = input[base_j] - input[base_i];
                        const int64_t dy = input[base_j + 1] - input[base_i + 1];
                        const int64_t dz = input[base_j + 2] - input[base_i + 2];
                        const int64_t radius_squared = dx * dx + dy * dy + dz * dz;
                        if (radius_squared >= cutoff_squared) continue;
                        const int64_t product = input[base_i + 3] * input[base_j + 3];
                        const int64_t energy_numerator = product * (cutoff_squared - radius_squared) * SCALE;
                        const int64_t energy_denominator = (1 + radius_squared) * (1 + cutoff_squared);
                        total_energy += trunc_div_i64(energy_numerator, energy_denominator);
                        const int64_t force_denominator = (1 + radius_squared) * (1 + radius_squared);
                        const int64_t pair_x = trunc_div_i64(-2 * product * dx * SCALE, force_denominator);
                        const int64_t pair_y = trunc_div_i64(-2 * product * dy * SCALE, force_denominator);
                        const int64_t pair_z = trunc_div_i64(-2 * product * dz * SCALE, force_denominator);
                        force_x[i] += pair_x; force_x[j] -= pair_x;
                        force_y[i] += pair_y; force_y[j] -= pair_y;
                        force_z[i] += pair_z; force_z[j] -= pair_z;
                        ++accepted_pairs;
                    }
                }
            }
        }
    }
    for (size_t i = 0; i < count; ++i) {
        store_i64_le(output, 8 * (3 * i), force_x[i]);
        store_i64_le(output, 8 * (3 * i + 1), force_y[i]);
        store_i64_le(output, 8 * (3 * i + 2), force_z[i]);
    }
    store_i64_le(output, 8 * (3 * count), total_energy);
    store_i64_le(output, 8 * (3 * count + 1), accepted_pairs);
    return (int64_t)output_bytes;
}
