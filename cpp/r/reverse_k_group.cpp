/* Reverse complete k-node groups by relinking a bounded index-based list. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t MAX_INPUT_LENGTH = MAX_N + 2;
}

extern "C" std::int64_t reverse_k_group(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t k = static_cast<std::size_t>(input[1]);
    if (length != n + 2) return -1;
    const std::size_t output_bytes = 8 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int64_t nodes[MAX_N]{};
    int next[MAX_N + 1];
    int head = -1;
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i] = input[i + 2];
        next[i] = -1;
        if (head < 0) head = static_cast<int>(i);
        else {
            int tail = head;
            while (next[tail] >= 0) tail = next[tail];
            next[tail] = static_cast<int>(i);
        }
    }
    std::size_t remaining = 0;
    for (int node = head; node >= 0; node = next[node]) ++remaining;
    constexpr int dummy = static_cast<int>(MAX_N);
    next[dummy] = head;
    int previous = dummy;
    while (remaining >= k) {
        const int current = next[previous];
        int moved = next[current];
        for (std::size_t step = 1; step < k; ++step) {
            next[current] = next[moved];
            next[moved] = next[previous];
            next[previous] = moved;
            moved = next[current];
        }
        previous = current;
        remaining -= k;
    }

    std::int64_t result[MAX_N]{};
    std::size_t index = 0;
    for (int node = next[dummy]; node >= 0; node = next[node]) result[index++] = nodes[node];
    for (std::size_t i = 0; i < n; ++i) {
        std::uint64_t bits = static_cast<std::uint64_t>(result[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
