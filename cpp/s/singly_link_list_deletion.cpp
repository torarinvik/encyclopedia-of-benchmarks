#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MAX_N = 64; }

extern "C" std::int64_t singly_link_list_deletion(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_N + 2) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 2 || input[1] < 1 || input[1] > static_cast<std::int64_t>(n)) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    const std::size_t bytes = 4 * (n - 1);
    if (output == nullptr || capacity < bytes) return -2;
    std::int32_t nodes[MAX_N]{};
    int next[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = static_cast<std::int32_t>(input[i + 2]);
        next[i] = i + 1 < n ? static_cast<int>(i + 1) : -1;
    }
    int head = 0;
    const auto position = static_cast<std::size_t>(input[1]);
    if (position == 1) head = next[head];
    else {
        int previous = head;
        for (std::size_t i = 2; i < position; ++i) previous = next[previous];
        const int removed = next[previous];
        next[previous] = next[removed];
    }
    int node = head;
    for (std::size_t i = 0; i < n - 1; ++i) {
        auto bits = static_cast<std::uint32_t>(nodes[node]);
        for (std::size_t byte = 0; byte < 4; ++byte) {
            output[i * 4 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
        if (i + 1 < n - 1) node = next[node];
    }
    return static_cast<std::int64_t>(bytes);
}
