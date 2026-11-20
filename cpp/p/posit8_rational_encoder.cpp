#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 32;
constexpr std::size_t max_words = 66;

std::int64_t positive_units(std::uint8_t code) {
    int cursor = 6;
    const int regime_bit = (code >> 6) & 1;
    int run = 0;
    while (cursor >= 0 && ((code >> cursor) & 1) == regime_bit) {
        ++run;
        --cursor;
    }
    const int regime = regime_bit != 0 ? run - 1 : -run;
    if (cursor >= 0) --cursor;
    int exponent = 0;
    for (int i = 0; i < 2; ++i) {
        exponent <<= 1;
        if (cursor >= 0) {
            exponent |= (code >> cursor) & 1;
            --cursor;
        }
    }
    const int width = cursor + 1;
    const int fraction = width > 0 ? code & ((1 << width) - 1) : 0;
    const int significand = (1 << width) + fraction;
    const int shift = 4 * regime + exponent + 24 - width;
    return static_cast<std::int64_t>(significand) << shift;
}

int compare_ratio_to_unit(std::uint64_t scaled, std::uint64_t denominator, std::uint64_t unit) {
    const auto quotient = scaled / denominator;
    const auto remainder = scaled % denominator;
    if (quotient < unit) return -1;
    if (quotient > unit) return 1;
    return remainder == 0 ? 0 : 1;
}

std::uint8_t encode_one(std::int64_t numerator, std::int64_t denominator) {
    if (numerator == 0) return 0;
    const bool negative = numerator < 0;
    const auto magnitude = static_cast<std::uint64_t>(negative ? -numerator : numerator);
    const auto scaled = magnitude << 24;
    std::uint8_t chosen;
    if (compare_ratio_to_unit(scaled, static_cast<std::uint64_t>(denominator), 1) <= 0) {
        chosen = 1;
    } else if (compare_ratio_to_unit(scaled, static_cast<std::uint64_t>(denominator),
                                    static_cast<std::uint64_t>(positive_units(127))) >= 0) {
        chosen = 127;
    } else {
        int low = 1, high = 127;
        while (low < high) {
            const int middle = low + (high - low) / 2;
            const auto candidate = static_cast<std::uint64_t>(positive_units(static_cast<std::uint8_t>(middle)));
            if (compare_ratio_to_unit(scaled, static_cast<std::uint64_t>(denominator), candidate) > 0) low = middle + 1;
            else high = middle;
        }
        const int upper = low, lower = upper - 1;
        const auto midpoint = static_cast<std::uint64_t>(positive_units(static_cast<std::uint8_t>(lower))) +
                             static_cast<std::uint64_t>(positive_units(static_cast<std::uint8_t>(upper)));
        const int midpoint_comparison = compare_ratio_to_unit(scaled << 1, static_cast<std::uint64_t>(denominator), midpoint);
        chosen = static_cast<std::uint8_t>(midpoint_comparison < 0 ? lower :
                 midpoint_comparison > 0 ? upper : ((lower & 1) == 0 ? lower : upper));
    }
    return negative ? static_cast<std::uint8_t>(0u - chosen) : chosen;
}
}

extern "C" std::int64_t posit8_rational_encoder(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_words) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_count) || length != 1 + static_cast<std::size_t>(raw_count) * 2) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    for (std::size_t i = 0; i < count; ++i) {
        const auto numerator = input[1 + 2 * i], denominator = input[2 + 2 * i];
        if (numerator < -INT64_C(2147483648) || numerator > INT64_C(2147483648) || denominator < 1 || denominator > INT64_C(2147483648)) return -1;
    }
    if (output == nullptr || capacity < count) return -2;
    std::array<std::uint8_t, max_count> staged{};
    for (std::size_t i = 0; i < count; ++i) staged[i] = encode_one(input[1 + 2 * i], input[2 + 2 * i]);
    for (std::size_t i = 0; i < count; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(count);
}
