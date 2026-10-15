// Remove a node by one-based distance from the tail in an index-based list.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_list_length = 1024;
constexpr std::size_t none = max_list_length;
}

extern "C" std::int64_t remove_nth_node_from_end_of_list(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_list_length + 1) return -1;
    const std::size_t list_length = length - 1;
    for (std::size_t index = 0; index < list_length; ++index)
        if (input[index + 1] < std::numeric_limits<std::int32_t>::min() ||
            input[index + 1] > std::numeric_limits<std::int32_t>::max()) return -1;
    if (input[0] < 1 || static_cast<std::uint64_t>(input[0]) > list_length) return -1;

    std::size_t next_node[max_list_length];
    for (std::size_t index = 0; index < list_length; ++index)
        next_node[index] = index + 1 < list_length ? index + 1 : none;
    std::size_t node = 0, counted = 0;
    while (node != none) {
        node = next_node[node];
        ++counted;
    }
    if (counted != list_length) return -1;

    const std::size_t steps_to_target = counted - static_cast<std::size_t>(input[0]);
    std::size_t before = none;
    node = 0;
    for (std::size_t step = 0; step < steps_to_target; ++step) {
        before = node;
        node = next_node[node];
    }
    const std::size_t head = before == none ? next_node[node] : 0;
    if (before != none) next_node[before] = next_node[node];

    const std::size_t output_count = counted - 1;
    const std::size_t output_bytes = output_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    node = head;
    std::size_t written = 0;
    while (node != none) {
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[node + 1]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
        node = next_node[node];
        ++written;
    }
    return written == output_count ? static_cast<std::int64_t>(written) : -1;
}
