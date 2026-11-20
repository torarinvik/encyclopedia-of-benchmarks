#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxTerms = 8;
constexpr std::size_t kMaxInputLength = 19;
constexpr std::int64_t kModulus = 998244353;

std::int64_t normalize(std::int64_t value) {
    value %= kModulus;
    return value < 0 ? value + kModulus : value;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    base = normalize(base);
    while (exponent > 0) {
        if (exponent & 1) result = result * base % kModulus;
        base = base * base % kModulus;
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t lentz_continued_fraction_convergents(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(kMaxTerms)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * count) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] >= kModulus) return -1;
    auto value = input[1];
    if (value == 0) return -1;
    auto c_ratio = value;
    std::int64_t d_ratio = 0;
    std::array<std::int64_t, kMaxTerms + 2> trace{};
    trace[0] = value;
    for (std::size_t index = 0; index < count; ++index) {
        const auto numerator = input[2 + 2 * index];
        const auto denominator = input[3 + 2 * index];
        const auto d_denominator = normalize(denominator + numerator * d_ratio);
        if (d_denominator == 0 || c_ratio == 0) return -1;
        const auto c_value = normalize(denominator
            + numerator * power(c_ratio, kModulus - 2));
        if (c_value == 0) return -1;
        d_ratio = power(d_denominator, kModulus - 2);
        value = value * c_value % kModulus * d_ratio % kModulus;
        c_ratio = c_value;
        trace[index + 1] = value;
    }
    const auto output_bytes = 8 * (count + 2);
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(count + 1));
    for (std::size_t i = 0; i <= count; ++i)
        store_i64_le(output, 8 * (i + 1), trace[i]);
    return static_cast<std::int64_t>(output_bytes);
}
