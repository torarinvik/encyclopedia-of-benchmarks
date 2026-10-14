/* Bounded doubly linked list with a portable index-based node pool. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; constexpr std::size_t capacity = 256; }

extern "C" std::int64_t doubly_linked_list_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2, none = capacity;
    std::int64_t node_value[capacity];
    std::size_t next_node[capacity], prev_node[capacity];
    for (std::size_t i = 0; i < capacity; ++i) next_node[i] = i + 1;
    std::size_t free_head = 0, head = none, tail = none, count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation], payload = values[2 * operation + 1];
        std::int64_t observed = 0; bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -1000000 || payload > 1000000 || count == capacity || free_head == none) return invalid_result;
            const auto node = free_head; free_head = next_node[node];
            node_value[node] = payload; next_node[node] = prev_node[node] = none;
            if (opcode == 0) {
                if (tail == none) head = node;
                else { prev_node[node] = tail; next_node[tail] = node; }
                tail = node;
            } else {
                if (head == none) tail = node;
                else { next_node[node] = head; prev_node[head] = node; }
                head = node;
            }
            ++count; returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return invalid_result;
            const auto node = opcode == 2 ? head : tail; observed = node_value[node];
            const auto before = prev_node[node], after = next_node[node];
            if (before == none) head = after; else next_node[before] = after;
            if (after == none) tail = before; else prev_node[after] = before;
            next_node[node] = free_head; free_head = node; --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return invalid_result;
            auto node = head;
            while (node != none && node_value[node] != payload) node = next_node[node];
            observed = static_cast<std::int64_t>(node != none);
            if (opcode == 4 && node != none) {
                const auto before = prev_node[node], after = next_node[node];
                if (before == none) head = after; else next_node[before] = after;
                if (after == none) tail = before; else prev_node[after] = before;
                next_node[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(count);
        } else return invalid_result;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    auto node = head; std::size_t index = 0;
    while (node != none) { checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (node_value[node] + 1000000); node = next_node[node]; ++index; }
    node = tail; index = 0;
    while (node != none) { checksum += (static_cast<std::int64_t>(operation_count + count + index) + 1) * (node_value[node] + 1000000); node = prev_node[node]; ++index; }
    return checksum;
}
