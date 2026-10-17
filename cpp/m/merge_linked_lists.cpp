#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_list_length = 32;
constexpr std::size_t max_total_nodes = 2 * max_list_length;
constexpr std::size_t max_parseable_input_length = 2 + max_total_nodes + 1;

struct Node {
    std::int32_t value;
    std::int32_t next;
};

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t merge_linked_lists(const std::int64_t *values,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (!values || length < 2 || length > max_parseable_input_length) return -1;
    const auto raw_first = values[0];
    const auto raw_second = values[1];
    if (raw_first < 0 || raw_first > static_cast<std::int64_t>(max_list_length) ||
        raw_second < 0 || raw_second > static_cast<std::int64_t>(max_list_length)) return -1;
    const auto first_length = static_cast<std::size_t>(raw_first);
    const auto second_length = static_cast<std::size_t>(raw_second);
    const auto total = first_length + second_length;
    if (total > max_total_nodes || length != 2 + total) return -1;

    std::array<Node, max_total_nodes> nodes{};
    for (std::size_t index = 0; index < first_length; ++index) {
        const auto value = values[2 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        nodes[index].value = static_cast<std::int32_t>(value);
        nodes[index].next = index + 1 < first_length ? static_cast<std::int32_t>(index + 1) : -1;
    }
    const auto second_start = first_length;
    for (std::size_t index = 0; index < second_length; ++index) {
        const auto value = values[2 + first_length + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        const auto node = second_start + index;
        nodes[node].value = static_cast<std::int32_t>(value);
        nodes[node].next = index + 1 < second_length ? static_cast<std::int32_t>(node + 1) : -1;
    }

    const std::int32_t head1 = first_length == 0 ? -1 : 0;
    const std::int32_t head2 = second_length == 0 ? -1 : static_cast<std::int32_t>(second_start);
    std::int32_t temp1 = head1;
    std::int32_t temp2 = head2;
    std::int32_t holder2 = -1;
    while (temp1 != -1 && temp2 != -1) {
        const auto holder1 = nodes[static_cast<std::size_t>(temp1)].next;
        nodes[static_cast<std::size_t>(temp1)].next = temp2;
        if (holder1 != -1) {
            holder2 = nodes[static_cast<std::size_t>(temp2)].next;
            nodes[static_cast<std::size_t>(temp2)].next = holder1;
        }
        temp1 = holder1;
        temp2 = holder2;
    }

    std::size_t output_count = 0;
    for (auto node = head1; node != -1; node = nodes[static_cast<std::size_t>(node)].next) {
        if (node < 0 || static_cast<std::size_t>(node) >= total || output_count >= total) return -1;
        ++output_count;
    }
    const auto required = output_count * 8;
    if (!output || output_capacity < required) return -2;

    auto node = head1;
    for (std::size_t index = 0; index < output_count; ++index) {
        store_i64_le(output, 8 * index, static_cast<std::int64_t>(nodes[static_cast<std::size_t>(node)].value));
        node = nodes[static_cast<std::size_t>(node)].next;
    }
    return static_cast<std::int64_t>(required);
}
