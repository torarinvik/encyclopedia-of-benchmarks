#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 5, MAX_P = 32, MAX_INPUT = 66, MAX_OUTPUT = 256;
constexpr std::int64_t MOD = 998244353;
void store_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[at + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t mul_mod2n_convolution(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 3 || length > MAX_INPUT || input[0] < 0 || input[0] > MAX_N) return -1;
    const auto p = std::size_t{1} << static_cast<unsigned>(input[0]);
    if (length != 1 + 2 * p) return -1;
    for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] >= MOD) return -1;
    const auto bytes = 8 * p;
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    std::int64_t a[MAX_P]{}, b[MAX_P]{}, result[MAX_P]{};
    for (std::size_t i = 0; i < p; ++i) { a[i] = input[1 + i]; b[i] = input[1 + p + i]; }
    const auto mask = p - 1;
    for (std::size_t i = 0; i < p; ++i) for (std::size_t j = 0; j < p; ++j) {
        const auto k = (i * j) & mask;
        result[k] = (result[k] + a[i] * b[j]) % MOD;
    }
    for (std::size_t i = 0; i < p; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
