/* Recursive maximum-difference pair, matching the pinned Python tie order. */
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
struct Pair { std::int64_t small, big; };
Pair solve(const std::int64_t *values, std::size_t n) {
    if (n == 1) return {values[0], values[0]};
    const std::size_t left_n = n / 2;
    const Pair left = solve(values, left_n), right = solve(values + left_n, n - left_n);
    std::int64_t min_left = values[0], max_right = values[left_n];
    for (std::size_t i = 1; i < left_n; ++i) if (values[i] < min_left) min_left = values[i];
    for (std::size_t i = left_n + 1; i < n; ++i) if (values[i] > max_right) max_right = values[i];
    const auto cross = max_right - min_left;
    const auto right_diff = right.big - right.small, left_diff = left.big - left.small;
    if (right_diff > cross && right_diff > left_diff) return right;
    if (left_diff > cross) return left;
    return {min_left, max_right};
}
void put_le(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits; std::memcpy(&bits, &value, 8);
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}
extern "C" std::int64_t max_difference_pair(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 2 || input[0] < 1 || input[0] > 128 || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
    if (capacity < 16 || !output) return -2;
    const Pair result = solve(input + 1, n);
    put_le(output, 0, result.small); put_le(output, 8, result.big);
    return 16;
}
