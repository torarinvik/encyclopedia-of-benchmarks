#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_K = 3, MAX_P = 32, MAX_INPUT = 69, MAX_OUTPUT = 256;
constexpr std::int64_t MOD = 998244353;
void store_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[at + b] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}
extern "C" std::int64_t multivariate_convolution(const std::int64_t *input, std::size_t length,
                                                  std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 1 || length > MAX_INPUT || input[0] < 0 || input[0] > MAX_K) return -1;
    const auto k = static_cast<std::size_t>(input[0]); if (length < 1 + k) return -1;
    std::size_t dims[MAX_K]{}, p = 1;
    for (std::size_t axis = 0; axis < k; ++axis) {
        const auto d0 = input[1 + axis];
        if (d0 < 2 || d0 > MAX_P || p > MAX_P / static_cast<std::size_t>(d0)) return -1;
        dims[axis] = static_cast<std::size_t>(d0); p *= dims[axis];
    }
    if (length != 1 + k + 2 * p) return -1;
    const auto start = 1 + k;
    for (std::size_t q = start; q < length; ++q) if (input[q] < 0 || input[q] >= MOD) return -1;
    const auto bytes = 8 * p; if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    std::int64_t a[MAX_P]{}, b[MAX_P]{}, result[MAX_P]{};
    for (std::size_t i = 0; i < p; ++i) { a[i] = input[start + i]; b[i] = input[start + p + i]; }
    for (std::size_t i = 0; i < p; ++i) for (std::size_t j = 0; j < p; ++j) {
        std::size_t target = 0, stride = 1; bool valid = true;
        for (std::size_t axis = 0; axis < k; ++axis) {
            const auto d = dims[axis], sum = (i / stride) % d + (j / stride) % d;
            if (sum >= d) { valid = false; break; }
            target += sum * stride; stride *= d;
        }
        if (valid) result[target] = (result[target] + a[i] * b[j]) % MOD;
    }
    for (std::size_t i = 0; i < p; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
