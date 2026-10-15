/* Recursively unlink every node whose signed 32-bit value matches the target. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_nodes = 1024; constexpr std::size_t none = max_nodes; }

static std::size_t remove_chain(const std::int64_t *input, std::size_t *next_node,
                                std::size_t node, std::size_t end, std::int64_t target) noexcept {
    if (node == end) return end;
    const auto next = next_node[node];
    if (input[node + 1] == target) return remove_chain(input, next_node, next, end, target);
    next_node[node] = remove_chain(input, next_node, next, end, target);
    return node;
}

extern "C" std::int64_t remove_linked_list_elements(const std::int64_t *input, std::size_t length,
                                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length == 0 || length > max_nodes + 1) return -1;
    const auto target = input[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    const auto node_count = length - 1;
    std::size_t next_node[max_nodes];
    for (std::size_t index = 0; index < node_count; ++index) {
        const auto value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        next_node[index] = index + 1;
    }
    if (node_count < max_nodes) next_node[node_count] = node_count;
    auto head = node_count == 0 ? node_count : std::size_t(0);
    head = remove_chain(input, next_node, head, node_count, target);
    std::size_t survivor_count = 0;
    for (auto node = head; node != node_count; node = next_node[node]) ++survivor_count;
    const auto output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (auto node = head; node != node_count; node = next_node[node]) {
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[node + 1]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? static_cast<std::int64_t>(written) : -1;
}
