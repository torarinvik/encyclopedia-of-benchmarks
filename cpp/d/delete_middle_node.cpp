/* Delete the floor(n / 2)-indexed node using the source's fast/slow traversal. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_nodes = 1024; }

extern "C" std::int64_t delete_middle_node(const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_nodes || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    if (length <= 1) return 0;

    std::size_t next_node[max_nodes + 1];
    for (std::size_t index = 0; index < length; ++index) next_node[index] = index + 1;
    next_node[length] = length;
    std::size_t node_count = 0;
    for (std::size_t cursor = 0; cursor != length; cursor = next_node[cursor]) ++node_count;
    std::size_t fast = 0, slow = 0, previous = length;
    while (next_node[fast] != length && next_node[next_node[fast]] != length) {
        previous = slow;
        slow = next_node[slow];
        fast = next_node[next_node[fast]];
    }
    if (node_count % 2 == 0) { previous = slow; slow = next_node[slow]; }
    next_node[previous] = next_node[slow];

    const auto survivor_count = node_count - 1;
    const auto output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t node = 0; node != length; node = next_node[node]) {
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[node]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? static_cast<std::int64_t>(written) : -1;
}
