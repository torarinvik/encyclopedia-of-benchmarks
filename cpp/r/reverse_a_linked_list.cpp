/* Reverse a bounded singly linked list represented by local node indices. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 128;
constexpr std::size_t MAX_INPUT_LENGTH = MAX_N + 1;
}

extern "C" std::int64_t reverse_a_linked_list(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    const std::size_t output_bytes = 4 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int32_t nodes[MAX_N]{};
    int next[MAX_N];
    int head = -1;
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = static_cast<std::int32_t>(input[i + 1]);
        next[i] = -1;
        if (head < 0) head = static_cast<int>(i);
        else {
            int tail = head;
            while (next[tail] >= 0) tail = next[tail];
            next[tail] = static_cast<int>(i);
        }
    }
    int previous = -1;
    int current = head;
    while (current >= 0) {
        const int next_node = next[current];
        next[current] = previous;
        previous = current;
        current = next_node;
    }
    head = previous;
    for (std::size_t index = 0; index < n; ++index) {
        int node = head;
        for (std::size_t step = 0; step < index; ++step) node = next[node];
        std::uint32_t bits = static_cast<std::uint32_t>(nodes[node]);
        for (std::size_t byte = 0; byte < 4; ++byte) {
            output[index * 4 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
