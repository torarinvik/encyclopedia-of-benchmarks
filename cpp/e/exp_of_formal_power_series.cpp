#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input = 66;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t exp_of_formal_power_series(const std::int64_t* input,
                                                    std::size_t length,
                                                    std::uint8_t* output,
                                                    std::size_t capacity)
{
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1] != 0) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, max_n> integer_inverse{};
    std::array<std::int64_t, max_n> exponential{};
    if (n > 1) integer_inverse[1] = 1;
    for (std::size_t k = 2; k < n; ++k)
        integer_inverse[k] = modulus - (modulus / static_cast<std::int64_t>(k)) *
            integer_inverse[static_cast<std::size_t>(modulus % static_cast<std::int64_t>(k))] % modulus;
    exponential[0] = 1;
    for (std::size_t degree = 1; degree < n; ++degree) {
        std::int64_t sum = 0;
        for (std::size_t i = 1; i <= degree; ++i) {
            auto term = (static_cast<std::int64_t>(i) * input[i + 1]) % modulus;
            term = term * exponential[degree - i] % modulus;
            sum = (sum + term) % modulus;
        }
        exponential[degree] = sum * integer_inverse[degree] % modulus;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, exponential[i]);
    return static_cast<std::int64_t>(bytes);
}
