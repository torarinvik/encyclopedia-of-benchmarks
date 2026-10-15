#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 1024;
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}
extern "C" std::int64_t sliding_window_maximum(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > max_length + 2) return -1;
    const auto n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_length) || k_value < 1 || k_value > static_cast<std::int64_t>(max_length)) return -1;
    const auto n = static_cast<std::size_t>(n_value), k = static_cast<std::size_t>(k_value);
    if (length != n + 2) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    const auto windows = n >= k ? n - k + 1 : 0;
    if (capacity < windows * 8 || (windows && !output)) return -2;
    std::size_t deque[max_length], head = 0, tail = 0, out = 0;
    for (std::size_t i = 0; i < n; ++i) {
        while (head < tail && deque[head] + k <= i) ++head;
        while (head < tail && input[2 + deque[tail - 1]] < input[2 + i]) --tail;
        deque[tail++] = i;
        if (i + 1 >= k) store_i64_le(output, out++ * 8, input[2 + deque[head]]);
    }
    return static_cast<std::int64_t>(windows);
}
