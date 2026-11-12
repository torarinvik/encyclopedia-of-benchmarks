#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 16;
constexpr std::size_t max_m = 16;
constexpr std::size_t max_input = 20;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t shift_of_sampling_points_of_polynomial(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    const auto start = input[2];
    if (length != n + 3 || start < 0 || start >= modulus) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 3] < 0 || input[i + 3] >= modulus) return -1;

    const auto bytes = 8 * m;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, max_n> differences{}, newton{}, factorial{}, inverse_factorial{};
    for (std::size_t i = 0; i < n; ++i) differences[i] = input[i + 3];
    factorial[0] = 1;
    for (std::size_t k = 1; k < n; ++k) factorial[k] = factorial[k - 1] * static_cast<std::int64_t>(k) % modulus;
    inverse_factorial[n - 1] = mod_pow(factorial[n - 1], modulus - 2);
    for (std::size_t k = n - 1; k > 0; --k)
        inverse_factorial[k - 1] = inverse_factorial[k] * static_cast<std::int64_t>(k) % modulus;
    for (std::size_t k = 0; k < n; ++k) {
        newton[k] = differences[0] * inverse_factorial[k] % modulus;
        for (std::size_t i = 0; i + k + 1 < n; ++i) {
            differences[i] = differences[i + 1] - differences[i];
            if (differences[i] < 0) differences[i] += modulus;
        }
    }
    for (std::size_t offset = 0; offset < m; ++offset) {
        auto x = start + static_cast<std::int64_t>(offset);
        if (x >= modulus) x -= modulus;
        std::int64_t basis = 1, value = 0;
        for (std::size_t k = 0; k < n; ++k) {
            value = (value + newton[k] * basis) % modulus;
            auto factor = x - static_cast<std::int64_t>(k);
            if (factor < 0) factor += modulus;
            basis = basis * factor % modulus;
        }
        store_le(output, 8 * offset, value);
    }
    return static_cast<std::int64_t>(bytes);
}
