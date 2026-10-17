#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;

int reverse_links(int *next, int previous, int current) noexcept {
    if (next[current] >= 0) {
        const int head = reverse_links(next, current, next[current]);
        next[current] = previous;
        next[previous] = -1;
        return head;
    }
    next[current] = previous;
    next[previous] = -1;
    return current;
}
}

extern "C" std::int64_t reverse_a_linked_list_using_recusion(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > MAX_N + 1) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    const std::size_t bytes = 4 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::int32_t nodes[MAX_N]{};
    int next[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = static_cast<std::int32_t>(input[i + 1]);
        next[i] = i + 1 < n ? static_cast<int>(i + 1) : -1;
    }
    int node = reverse_links(next, 0, next[0]);
    for (std::size_t i = 0; i < n; ++i) {
        auto bits = static_cast<std::uint32_t>(nodes[node]);
        for (std::size_t byte = 0; byte < 4; ++byte) {
            output[i * 4 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
        if (i + 1 < n) node = next[node];
    }
    return static_cast<std::int64_t>(bytes);
}
