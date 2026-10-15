// Bounded circular doubly linked-list operation trace with a sentinel ring.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circular_doubly_linked_list_benchmark(const std::int64_t* values, std::size_t length) noexcept
{
    constexpr std::size_t capacity = 256, sentinel = capacity;
    constexpr std::int64_t offset = 1'000'000, max_index = 1'000'000;
    if (length > 1024 || length % 2 != 0) return -1;
    const std::size_t operation_count = length / 2;
    std::array<std::int64_t, capacity> node_value{};
    std::array<std::size_t, capacity + 1> next_node{}, prev_node{};
    for (std::size_t i = 0; i < capacity; ++i) next_node[i] = i + 1;
    std::size_t free_head = 0, count = 0;
    next_node[sentinel] = sentinel;
    prev_node[sentinel] = sentinel;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation], payload = values[2 * operation + 1];
        std::int64_t observed = 0;
        bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -offset || payload > offset || count == capacity || free_head == sentinel) return -1;
            const auto node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            const auto before = opcode == 0 ? prev_node[sentinel] : sentinel;
            const auto after = opcode == 0 ? sentinel : next_node[sentinel];
            next_node[node] = after; prev_node[node] = before;
            next_node[before] = node; prev_node[after] = node;
            ++count; returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            const auto node = opcode == 2 ? next_node[sentinel] : prev_node[sentinel];
            observed = node_value[node];
            next_node[prev_node[node]] = next_node[node];
            prev_node[next_node[node]] = prev_node[node];
            next_node[node] = free_head; free_head = node; --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -offset || payload > offset) return -1;
            auto node = next_node[sentinel];
            while (node != sentinel && node_value[node] != payload) node = next_node[node];
            observed = node != sentinel;
            if (opcode == 4 && node != sentinel) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = static_cast<std::int64_t>(count);
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > max_index || count == 0) return -1;
            if (opcode == 8 && static_cast<std::uint64_t>(payload) >= count) return -1;
            const auto index = opcode == 7 ? static_cast<std::size_t>(payload % static_cast<std::int64_t>(count)) : static_cast<std::size_t>(payload);
            std::size_t node;
            if (index <= count / 2) {
                node = next_node[sentinel];
                for (std::size_t i = 0; i < index; ++i) node = next_node[node];
            } else {
                node = prev_node[sentinel];
                for (std::size_t i = count - 1; i > index; --i) node = prev_node[node];
            }
            observed = node_value[node];
            if (opcode == 8) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; --count;
            }
        } else return -1;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + offset);
    }
    std::size_t node = next_node[sentinel], index = 0;
    while (node != sentinel) {
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (node_value[node] + offset);
        node = next_node[node]; ++index;
    }
    node = prev_node[sentinel]; index = 0;
    while (node != sentinel) {
        checksum += (static_cast<std::int64_t>(operation_count + count + index) + 1) * (node_value[node] + offset);
        node = prev_node[node]; ++index;
    }
    return checksum;
}
