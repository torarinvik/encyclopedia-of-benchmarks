#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_N = 64; }

extern "C" std::int64_t rotate_singly_linked_lists(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_N + 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N) ||
        input[1] < 0 || input[1] > INT32_MAX) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto k = input[1];
    if (length != n + 2) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    const std::size_t bytes = 8 * (n + 1);
    if (output == nullptr || capacity < bytes) return -2;

    std::int32_t nodes[MAX_N]{};
    int next[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = static_cast<std::int32_t>(input[i + 2]);
        next[i] = i + 1 < n ? static_cast<int>(i + 1) : -1;
    }
    int head = n > 0 ? 0 : -1;
    if (n > 1 && k > 0) {
        const int tail = static_cast<int>(n) - 1;
        next[tail] = head;
        const auto shift = static_cast<std::size_t>(k % static_cast<std::int64_t>(n));
        const auto steps = n - shift;
        int new_tail = tail;
        for (std::size_t i = 0; i < steps; ++i) new_tail = next[new_tail];
        head = next[new_tail];
        next[new_tail] = -1;
    }
    std::uint64_t count = n;
    for (std::size_t b = 0; b < 8; ++b) { output[b] = static_cast<std::uint8_t>(count & 255); count >>= 8; }
    int node = head;
    for (std::size_t i = 0; i < n; ++i) {
        std::uint64_t bits = static_cast<std::uint64_t>(static_cast<std::int64_t>(nodes[node]));
        for (std::size_t b = 0; b < 8; ++b) { output[8 + i * 8 + b] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
        if (i + 1 < n) node = next[node];
    }
    return static_cast<std::int64_t>(bytes);
}
