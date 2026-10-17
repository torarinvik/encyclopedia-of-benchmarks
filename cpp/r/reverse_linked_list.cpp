/* Reverse a bounded doubly linked chain represented by local node indices. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t MAX_INPUT_LENGTH = MAX_N + 1;
}

extern "C" std::int64_t reverse_linked_list(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    const std::size_t output_bytes = 8 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int64_t nodes[MAX_N]{};
    int next[MAX_N], previous_link[MAX_N];
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = input[i + 1];
        next[i] = i + 1 < n ? static_cast<int>(i + 1) : -1;
        previous_link[i] = i > 0 ? static_cast<int>(i - 1) : -1;
    }
    int previous = -1;
    int current = 0;
    while (current >= 0) {
        const int next_node = next[current];
        next[current] = previous;
        previous_link[current] = next_node;
        previous = current;
        current = next_node;
    }
    const int head = previous;
    int node = head;
    int expected_previous = -1;
    std::int64_t result[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        if (node < 0 || previous_link[node] != expected_previous) return -1;
        result[i] = nodes[node];
        expected_previous = node;
        node = next[node];
    }
    if (node >= 0) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        std::uint64_t bits = static_cast<std::uint64_t>(result[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
