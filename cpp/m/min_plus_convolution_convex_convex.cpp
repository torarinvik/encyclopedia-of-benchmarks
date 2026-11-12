#include <cstddef>
#include <cstdint>
#include <array>

namespace {
constexpr std::size_t MAX_INPUT = 259, MAX_OUTPUT = 2040, MAX_N = 128, MAX_M = 128;
constexpr std::size_t MAX_OUTPUT_ELEMENTS = MAX_N + MAX_M - 1;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

bool is_convex(const std::int64_t *values, std::size_t length) {
    for (std::size_t i = 0; i + 2 < length; ++i)
        if (values[i + 1] - values[i] > values[i + 2] - values[i + 1]) return false;
    return true;
}
}

extern "C" std::int64_t min_plus_convolution_convex_convex(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    if (length != 2 + n + m) return -1;
    const auto *a = input + 2, *b = input + 2 + n;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1'000'000'000) return -1;
    if (!is_convex(a, n) || !is_convex(b, m)) return -1;

    const auto count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, MAX_OUTPUT_ELEMENTS> result{};
    result[0] = a[0] + b[0];
    std::size_t ai = 0, bi = 0, out = 1;
    while (ai + 1 < n || bi + 1 < m) {
        std::int64_t slope;
        if (bi + 1 == m || (ai + 1 < n && a[ai + 1] - a[ai] <= b[bi + 1] - b[bi])) {
            slope = a[ai + 1] - a[ai];
            ++ai;
        } else {
            slope = b[bi + 1] - b[bi];
            ++bi;
        }
        result[out] = result[out - 1] + slope;
        ++out;
    }
    for (std::size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
