#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_t = 8;
constexpr std::int64_t max_component = 1'000'000;

std::int64_t nearest_quotient(std::int64_t numerator, std::int64_t denominator) noexcept {
    const auto sign = numerator < 0 ? -1 : 1;
    const auto magnitude = numerator < 0 ? -numerator : numerator;
    auto quotient = magnitude / denominator;
    const auto remainder = magnitude % denominator;
    if (2 * remainder >= denominator) ++quotient;
    return sign * quotient;
}

struct Gaussian {
    std::int64_t real;
    std::int64_t imaginary;
};

Gaussian gaussian_gcd(std::int64_t ar, std::int64_t ai,
                      std::int64_t br, std::int64_t bi) noexcept {
    while (br != 0 || bi != 0) {
        const auto denominator = br * br + bi * bi;
        const auto qr = nearest_quotient(ar * br + ai * bi, denominator);
        const auto qi = nearest_quotient(ai * br - ar * bi, denominator);
        const auto rr = ar - (qr * br - qi * bi);
        const auto ri = ai - (qr * bi + qi * br);
        ar = br;
        ai = bi;
        br = rr;
        bi = ri;
    }
    if (ar != 0 || ai != 0) {
        for (int rotation = 0; rotation < 4 && !(ar > 0 && ai >= 0); ++rotation) {
            const auto old_real = ar;
            ar = -ai;
            ai = old_real;
        }
    }
    return {ar, ai};
}

void write_u32(std::uint8_t *output, std::size_t offset, std::uint32_t value) noexcept {
    output[offset] = static_cast<std::uint8_t>(value);
    output[offset + 1] = static_cast<std::uint8_t>(value >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(value >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(value >> 24);
}
} // namespace

extern "C" std::int64_t gcd_of_gaussian_integers(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > 1 + 4 * max_t) return -1;
    const auto t64 = input[0];
    if (t64 < 1 || t64 > static_cast<std::int64_t>(max_t)) return -1;
    const auto t = static_cast<std::size_t>(t64);
    if (length != 1 + 4 * t) return -1;

    std::int64_t values[4 * max_t]{};
    for (std::size_t i = 0; i < 4 * t; ++i) {
        if (input[i + 1] < -max_component || input[i + 1] > max_component) return -1;
        values[i] = input[i + 1];
    }
    const auto required = 8 * t;
    if (output == nullptr || capacity < required) return -2;

    for (std::size_t test = 0; test < t; ++test) {
        const auto result = gaussian_gcd(values[4 * test], values[4 * test + 1],
                                         values[4 * test + 2], values[4 * test + 3]);
        write_u32(output, 8 * test, static_cast<std::uint32_t>(result.real));
        write_u32(output, 8 * test + 4, static_cast<std::uint32_t>(result.imaginary));
    }
    return static_cast<std::int64_t>(required);
}
