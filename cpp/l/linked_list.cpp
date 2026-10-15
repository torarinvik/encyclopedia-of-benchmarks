/* Bounded singly linked list with a portable index-based node pool. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; constexpr std::size_t capacity = 256; }

extern "C" std::int64_t linked_list_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2, none = capacity;
    std::int64_t node_value[capacity];
    std::size_t next_node[capacity];
    for (std::size_t i = 0; i < capacity; ++i) next_node[i] = i + 1;
    std::size_t free_head = 0, head = none, tail = none, count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation], payload = values[2 * operation + 1];
        std::int64_t observed = 0; bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -1000000 || payload > 1000000 || count == capacity || free_head == none) return invalid_result;
            const auto node = free_head; free_head = next_node[node]; node_value[node] = payload;
            if (opcode == 0) {
                if (tail == none) head = node; else next_node[tail] = node;
                tail = node; next_node[node] = none;
            } else {
                next_node[node] = head; head = node;
                if (tail == none) tail = node;
            }
            ++count; returns_value = false;
        } else if (opcode == 2) {
            if (payload != 0 || count == 0) return invalid_result;
            const auto node = head; observed = node_value[node]; head = next_node[node];
            if (head == none) tail = none;
            next_node[node] = free_head; free_head = node; --count;
        } else if (opcode == 3) {
            if (payload != 0 || count == 0) return invalid_result;
            const auto node = tail; observed = node_value[node];
            if (head == tail) head = tail = none;
            else {
                auto before = head;
                while (next_node[before] != tail) before = next_node[before];
                tail = before; next_node[before] = none;
            }
            next_node[node] = free_head; free_head = node; --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return invalid_result;
            auto before = none, node = head;
            while (node != none && node_value[node] != payload) { before = node; node = next_node[node]; }
            observed = static_cast<std::int64_t>(node != none);
            if (opcode == 4 && node != none) {
                if (before == none) head = next_node[node]; else next_node[before] = next_node[node];
                if (tail == node) tail = before;
                next_node[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(count);
        } else if (opcode == 7) {
            if (payload != 0) return invalid_result;
            auto previous = none, node = head;
            tail = head;
            while (node != none) {
                const auto next = next_node[node];
                next_node[node] = previous; previous = node; node = next;
            }
            head = previous;
            returns_value = false;
        } else return invalid_result;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    auto node = head; std::size_t index = 0;
    while (node != none) { checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (node_value[node] + 1000000); node = next_node[node]; ++index; }
    return checksum;
}
