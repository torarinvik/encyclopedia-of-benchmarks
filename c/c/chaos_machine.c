/* Seeded portable port of the pinned logistic-map/Xorshift machine. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static double fraction_one(double value) { return value - floor(value); }
static double round_ten(double value) {
    if (value <= 0.0) return 0.0;
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const uint64_t exponent = (bits >> 52) & 0x7ff;
    if (exponent == 0) return 0.0;
    const uint64_t mantissa = (UINT64_C(1) << 52) | (bits & ((UINT64_C(1) << 52) - 1));
    const uint64_t low_product = (mantissa & UINT64_C(0xffffffff)) * UINT64_C(9765625);
    const uint64_t high_product = (mantissa >> 32) * UINT64_C(9765625);
    const uint64_t shifted_high = high_product << 32;
    const uint64_t low = shifted_high + low_product;
    const uint64_t high = (high_product >> 32) + (low < shifted_high);
    const int shift = 1065 - (int)exponent;
    if (shift > 77) return 0.0;
    uint64_t rounded;
    int relation;
    if (shift < 64) {
        rounded = (high << (64 - shift)) | (low >> shift);
        const uint64_t remainder = low & ((UINT64_C(1) << shift) - 1);
        const uint64_t half = UINT64_C(1) << (shift - 1);
        relation = remainder > half ? 1 : remainder < half ? -1 : 0;
    } else if (shift == 64) {
        rounded = high;
        const uint64_t half = UINT64_C(1) << 63;
        relation = low > half ? 1 : low < half ? -1 : 0;
    } else {
        const int upper_bits = shift - 64;
        rounded = high >> upper_bits;
        const uint64_t remainder_high = high & ((UINT64_C(1) << upper_bits) - 1);
        const uint64_t half_high = UINT64_C(1) << (upper_bits - 1);
        relation = remainder_high > half_high || (remainder_high == half_high && low != 0)
            ? 1 : remainder_high < half_high ? -1 : 0;
    }
    if (relation > 0 || (relation == 0 && (rounded & 1) != 0)) ++rounded;
    return (double)rounded / 10000000000.0;
}
static uint32_t pull(uint64_t *machine_time, double buffer[5], double params[5]) {
    const size_t key = (size_t)(*machine_time % 5);
    for (size_t step = 0; step < 3; ++step) {
        const double rate = params[key], value = buffer[key];
        buffer[key] = round_ten(rate * value * (1.0 - value));
        params[key] = fraction_one((double)(*machine_time) * 0.01 + rate * 1.01) + 3.0;
    }
    uint64_t x = (uint64_t)(buffer[(key + 2) % 5] * 10000000000.0);
    uint64_t y = (uint64_t)(buffer[(key + 3) % 5] * 10000000000.0);
    ++*machine_time;
    x ^= y >> 13; y ^= x << 17; x ^= y >> 5;
    return (uint32_t)(x & UINT32_MAX);
}
int64_t chaos_machine(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > 66) return -1;
    if (values[0] < 0 || values[0] > 64 || length != (size_t)values[0] + 2) return -1;
    const size_t seed_count = (size_t)values[0];
    const int64_t pull_count_input = values[length - 1];
    if (pull_count_input < 0 || pull_count_input > 64) return -1;
    for (size_t index = 0; index < seed_count; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 1000000) return -1;
    const size_t pull_count = (size_t)pull_count_input, required = 4 * pull_count;
    if (required > output_capacity || (required != 0 && output == NULL)) return -2;
    double buffer[5] = {0.33, 0.44, 0.55, 0.44, 0.33};
    double params[5] = {0.0, 0.0, 0.0, 0.0, 0.0};
    uint64_t machine_time = 0;
    for (size_t seed_index = 0; seed_index < seed_count; ++seed_index) {
        const double seed = (double)values[seed_index + 1];
        for (size_t key = 0; key < 5; ++key) {
            if (buffer[key] == 0.0) return -1;
            const double evolution = seed / buffer[key];
            const double value = fraction_one(buffer[(key + 1) % 5] + evolution);
            const double rate = fraction_one(params[key] + evolution) + 3.0;
            buffer[key] = round_ten(rate * value * (1.0 - value));
            params[key] = rate;
        }
        ++machine_time;
    }
    for (size_t index = 0; index < pull_count; ++index) {
        const uint32_t result = pull(&machine_time, buffer, params);
        for (size_t byte = 0; byte < 4; ++byte) output[4 * index + byte] = (uint8_t)(result >> (8 * byte));
    }
    return (int64_t)required;
}
