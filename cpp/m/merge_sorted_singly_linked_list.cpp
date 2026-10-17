#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 128;
constexpr std::size_t max_input_length = 130;
constexpr std::size_t max_output_bytes = 12 * max_nodes;

struct ListNode {
    std::int32_t value;
    std::int32_t next;
    std::int32_t origin;
    std::int32_t position;
};

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t merge_sorted_singly_linked_list(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto len_a = static_cast<std::size_t>(input[0]);
    if (len_a > length - 2) return -1;
    const auto len_b_pos = 1 + len_a;
    const auto raw_len_b = input[len_b_pos];
    if (raw_len_b < 0 || raw_len_b > static_cast<std::int64_t>(max_nodes - len_a)) return -1;
    const auto len_b = static_cast<std::size_t>(raw_len_b);
    const auto total = len_a + len_b;
    if (length != 2 + total) return -1;

    ListNode nodes[max_nodes];
    for (std::size_t i = 0; i < len_a; ++i) {
        const auto raw = input[1 + i];
        if (raw < INT32_MIN || raw > INT32_MAX || (i > 0 && input[i] > raw)) return -1;
        nodes[i] = {static_cast<std::int32_t>(raw), i + 1 < len_a ? static_cast<std::int32_t>(i + 1) : -1, 0, static_cast<std::int32_t>(i)};
    }
    const auto b_start = len_b_pos + 1;
    for (std::size_t i = 0; i < len_b; ++i) {
        const auto raw = input[b_start + i];
        if (raw < INT32_MIN || raw > INT32_MAX || (i > 0 && input[b_start + i - 1] > raw)) return -1;
        const auto node = len_a + i;
        nodes[node] = {static_cast<std::int32_t>(raw), i + 1 < len_b ? static_cast<std::int32_t>(node + 1) : -1, 1, static_cast<std::int32_t>(i)};
    }

    std::int32_t head_a = len_a == 0 ? -1 : 0;
    std::int32_t head_b = len_b == 0 ? -1 : static_cast<std::int32_t>(len_a);
    std::int32_t merged_head = -1, tail = -1;
    while (head_a >= 0 && head_b >= 0) {
        std::int32_t node;
        if (nodes[head_a].value <= nodes[head_b].value) {
            node = head_a;
            head_a = nodes[node].next;
        } else {
            node = head_b;
            head_b = nodes[node].next;
        }
        if (tail < 0) merged_head = node;
        else nodes[tail].next = node;
        tail = node;
    }
    const std::int32_t remainder = head_a >= 0 ? head_a : head_b;
    if (tail < 0) merged_head = remainder;
    else nodes[tail].next = remainder;

    const auto bytes = 12 * total;
    if (bytes > max_output_bytes || output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    std::size_t written = 0;
    for (auto node = merged_head; node >= 0; node = nodes[node].next) {
        put_i32_le(buffer, written, nodes[node].value);
        put_i32_le(buffer, written + 4, nodes[node].origin);
        put_i32_le(buffer, written + 8, nodes[node].position);
        written += 12;
    }
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
