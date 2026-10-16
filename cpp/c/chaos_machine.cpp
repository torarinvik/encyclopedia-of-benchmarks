// Seeded portable port of the pinned logistic-map/Xorshift machine.
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
double fraction_one(double value) { return value - std::floor(value); }
double round_ten(double value) {
    if (value <= 0.0) return 0.0;
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const std::uint64_t exponent = (bits >> 52) & 0x7ff;
    if (exponent == 0) return 0.0;
    const std::uint64_t mantissa = (UINT64_C(1) << 52) | (bits & ((UINT64_C(1) << 52) - 1));
    const std::uint64_t low_product = (mantissa & UINT64_C(0xffffffff)) * UINT64_C(9765625);
    const std::uint64_t high_product = (mantissa >> 32) * UINT64_C(9765625);
    const std::uint64_t shifted_high = high_product << 32;
    const std::uint64_t low = shifted_high + low_product;
    const std::uint64_t high = (high_product >> 32) + (low < shifted_high);
    const int shift = 1065 - static_cast<int>(exponent);
    if (shift > 77) return 0.0;
    std::uint64_t rounded;
    int relation;
    if (shift < 64) {
        rounded = (high << (64 - shift)) | (low >> shift);
        const std::uint64_t remainder = low & ((UINT64_C(1) << shift) - 1);
        const std::uint64_t half = UINT64_C(1) << (shift - 1);
        relation = remainder > half ? 1 : remainder < half ? -1 : 0;
    } else if (shift == 64) {
        rounded = high;
        const std::uint64_t half = UINT64_C(1) << 63;
        relation = low > half ? 1 : low < half ? -1 : 0;
    } else {
        const int upper_bits = shift - 64;
        rounded = high >> upper_bits;
        const std::uint64_t remainder_high = high & ((UINT64_C(1) << upper_bits) - 1);
        const std::uint64_t half_high = UINT64_C(1) << (upper_bits - 1);
        relation = remainder_high > half_high || (remainder_high == half_high && low != 0)
            ? 1 : remainder_high < half_high ? -1 : 0;
    }
    if (relation > 0 || (relation == 0 && (rounded & 1) != 0)) ++rounded;
    return static_cast<double>(rounded) / 10000000000.0;
}
std::uint32_t pull(std::uint64_t &machine_time, double buffer[5], double params[5]) {
    const std::size_t key = static_cast<std::size_t>(machine_time % 5);
    for (std::size_t step = 0; step < 3; ++step) {
        const double rate = params[key], value = buffer[key];
        buffer[key] = round_ten(rate * value * (1.0 - value));
        params[key] = fraction_one(static_cast<double>(machine_time) * 0.01 + rate * 1.01) + 3.0;
    }
    std::uint64_t x = static_cast<std::uint64_t>(buffer[(key + 2) % 5] * 10000000000.0);
    std::uint64_t y = static_cast<std::uint64_t>(buffer[(key + 3) % 5] * 10000000000.0);
    ++machine_time;
    x ^= y >> 13; y ^= x << 17; x ^= y >> 5;
    return static_cast<std::uint32_t>(x & UINT32_MAX);
}
}
extern "C" std::int64_t chaos_machine(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > 66) return -1;
    if (values[0] < 0 || values[0] > 64 || length != static_cast<std::size_t>(values[0]) + 2) return -1;
    const std::size_t seed_count = static_cast<std::size_t>(values[0]);
    const std::int64_t pull_count_input = values[length - 1];
    if (pull_count_input < 0 || pull_count_input > 64) return -1;
    for (std::size_t index = 0; index < seed_count; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 1000000) return -1;
    const std::size_t pull_count = static_cast<std::size_t>(pull_count_input), required = 4 * pull_count;
    if (required > output_capacity || (required != 0 && output == nullptr)) return -2;
    double buffer[5] = {0.33, 0.44, 0.55, 0.44, 0.33};
    double params[5] = {0.0, 0.0, 0.0, 0.0, 0.0};
    std::uint64_t machine_time = 0;
    for (std::size_t seed_index = 0; seed_index < seed_count; ++seed_index) {
        const double seed = static_cast<double>(values[seed_index + 1]);
        for (std::size_t key = 0; key < 5; ++key) {
            if (buffer[key] == 0.0) return -1;
            const double evolution = seed / buffer[key];
            const double value = fraction_one(buffer[(key + 1) % 5] + evolution);
            const double rate = fraction_one(params[key] + evolution) + 3.0;
            buffer[key] = round_ten(rate * value * (1.0 - value));
            params[key] = rate;
        }
        ++machine_time;
    }
    for (std::size_t index = 0; index < pull_count; ++index) {
        const std::uint32_t result = pull(machine_time, buffer, params);
        for (std::size_t byte = 0; byte < 4; ++byte) output[4 * index + byte] = static_cast<std::uint8_t>(result >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
