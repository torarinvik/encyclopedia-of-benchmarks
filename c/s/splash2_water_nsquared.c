#include <stddef.h>
#include <stdint.h>

#define MAX_MOLECULES 64
#define MAX_VALID_INPUT_VALUES (3 + 4 * MAX_MOLECULES)
#define MAX_PARSEABLE_INPUT_VALUES (MAX_VALID_INPUT_VALUES + 1)
#define MAX_OUTPUT_WORDS (3 * MAX_MOLECULES + 2)
#define SCALE INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t splash2_water_nsquared(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_VALUES)
        return -1;
    const int64_t n_raw = input[0], grid_raw = input[1], range_raw = input[2];
    if (n_raw < 0 || n_raw > MAX_MOLECULES || grid_raw < 1 || grid_raw > 8 ||
        range_raw < 1 || range_raw > 4)
        return -1;
    const size_t n = (size_t)n_raw;
    const int64_t side = grid_raw * range_raw;
    if (length != 3 + 4 * n) return -1;

    int64_t x[MAX_MOLECULES], y[MAX_MOLECULES], z[MAX_MOLECULES], q[MAX_MOLECULES];
    for (size_t i = 0; i < n; ++i) {
        const size_t at = 3 + 4 * i;
        x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; q[i] = input[at + 3];
        if (x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side ||
            z[i] < 0 || z[i] >= side || q[i] < -4 || q[i] > 4)
            return -1;
    }

    int64_t force[MAX_MOLECULES][3] = {{0}};
    int64_t energy = 0, accepted_pairs = 0;
    const int64_t range2 = range_raw * range_raw;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            const int64_t dx = x[j] - x[i], dy = y[j] - y[i], dz = z[j] - z[i];
            const int64_t r2 = dx * dx + dy * dy + dz * dz;
            if (r2 >= range2) continue;
            const int64_t charge_product = q[i] * q[j];
            const int64_t energy_numerator = charge_product * (range2 - r2) * SCALE;
            const int64_t energy_denominator = (1 + r2) * (1 + range2);
            energy += energy_numerator / energy_denominator;
            const int64_t force_denominator = (1 + r2) * (1 + r2);
            const int64_t fx = (-2 * charge_product * dx * SCALE) / force_denominator;
            const int64_t fy = (-2 * charge_product * dy * SCALE) / force_denominator;
            const int64_t fz = (-2 * charge_product * dz * SCALE) / force_denominator;
            force[i][0] += fx; force[i][1] += fy; force[i][2] += fz;
            force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz;
            ++accepted_pairs;
        }
    }

    const size_t output_words = 3 * n + 2;
    const size_t output_bytes = output_words * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t result[MAX_OUTPUT_WORDS] = {0};
    for (size_t i = 0; i < n; ++i)
        for (size_t axis = 0; axis < 3; ++axis)
            result[3 * i + axis] = force[i][axis];
    result[3 * n] = energy;
    result[3 * n + 1] = accepted_pairs;
    for (size_t word = 0; word < output_words; ++word)
        store_i64_le(output, 8 * word, result[word]);
    return (int64_t)output_bytes;
}
