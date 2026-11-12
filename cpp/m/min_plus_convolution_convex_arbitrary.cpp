#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_INPUT = 67, MAX_OUTPUT = 504, MAX_N = 32, MAX_M = 32;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t min_plus_convolution_convex_arbitrary(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    if (length != 2 + n + m) return -1;
    const auto *a = input + 2, *b = input + 2 + n;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1000000000) return -1;
    for (std::size_t i = 0; i + 2 < n; ++i)
        if (a[i + 1] - a[i] > a[i + 2] - a[i + 1]) return -1;
    const auto count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    std::int64_t result[MAX_N + MAX_M - 1];
    std::size_t stack[128][4], top = 0;
    stack[top][0] = 0; stack[top][1] = count - 1; stack[top][2] = 0; stack[top][3] = m - 1; ++top;
    while (top) {
        --top;
        const auto left = stack[top][0], right = stack[top][1];
        const auto opt_left = stack[top][2], opt_right = stack[top][3];
        if (left > right) continue;
        const auto mid = left + (right - left) / 2;
        auto low = opt_left;
        if (mid > n - 1 && low < mid - (n - 1)) low = mid - (n - 1);
        auto high = opt_right;
        if (high > m - 1) high = m - 1;
        if (high > mid) high = mid;
        auto best_value = std::numeric_limits<std::int64_t>::max();
        auto best_j = low;
        for (auto j = low; j <= high; ++j) {
            const auto candidate = a[mid - j] + b[j];
            if (candidate < best_value) { best_value = candidate; best_j = j; }
        }
        result[mid] = best_value;
        if (mid < right) { stack[top][0] = mid + 1; stack[top][1] = right; stack[top][2] = best_j; stack[top][3] = opt_right; ++top; }
        if (left < mid) { stack[top][0] = left; stack[top][1] = mid - 1; stack[top][2] = opt_left; stack[top][3] = best_j; ++top; }
    }
    for (std::size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
