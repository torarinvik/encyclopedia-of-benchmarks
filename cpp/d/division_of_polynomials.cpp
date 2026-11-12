#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input = 131;
constexpr std::size_t max_output_bytes = 536;

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

std::size_t trim(const std::array<std::int64_t, max_n>& polynomial, std::size_t length) {
    while (length > 0 && polynomial[length - 1] == 0) --length;
    return length;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t division_of_polynomials(const std::int64_t* input,
                                                 std::size_t length,
                                                 std::uint8_t* output,
                                                 std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)
            || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;

    std::array<std::int64_t, max_n> work{};
    std::array<std::int64_t, max_n> quotient{};
    for (std::size_t i = 0; i < n; ++i) {
        work[i] = input[2 + i];
        if (work[i] < 0 || work[i] >= modulus) return -1;
    }
    for (std::size_t i = 0; i < m; ++i)
        if (input[2 + n + i] < 0 || input[2 + n + i] >= modulus) return -1;
    if (work[n - 1] == 0 || input[2 + n + m - 1] == 0) return -1;

    std::size_t quotient_bound = 0;
    if (n >= m) {
        quotient_bound = n - m + 1;
        const auto inverse_leading = power_mod(input[2 + n + m - 1], modulus - 2);
        for (std::size_t shift_plus_one = quotient_bound; shift_plus_one > 0; --shift_plus_one) {
            const auto shift = shift_plus_one - 1;
            const auto factor = work[shift + m - 1] * inverse_leading % modulus;
            quotient[shift] = factor;
            for (std::size_t j = 0; j < m; ++j) {
                auto value = (work[shift + j] - factor * input[2 + n + j]) % modulus;
                if (value < 0) value += modulus;
                work[shift + j] = value;
            }
        }
    }

    const auto quotient_length = trim(quotient, quotient_bound);
    const auto remainder_bound = n < m ? n : m;
    const auto remainder_length = trim(work, remainder_bound);
    const auto bytes = 8 * (2 + quotient_length + remainder_length);
    if (bytes > max_output_bytes) return -1;
    if (output == nullptr || capacity < bytes) return -2;

    store_le(output, 0, static_cast<std::int64_t>(quotient_length));
    store_le(output, 8, static_cast<std::int64_t>(remainder_length));
    std::size_t offset = 16;
    for (std::size_t i = 0; i < quotient_length; ++i, offset += 8) store_le(output, offset, quotient[i]);
    for (std::size_t i = 0; i < remainder_length; ++i, offset += 8) store_le(output, offset, work[i]);
    return static_cast<std::int64_t>(bytes);
}
