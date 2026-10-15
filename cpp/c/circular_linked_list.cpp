// Bounded singly circular linked-list operation trace with a sentinel ring.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circular_linked_list_benchmark(const std::int64_t *values,
                                                                std::size_t length) noexcept {
    constexpr std::size_t capacity = 256, sentinel = capacity;
    constexpr std::int64_t offset = 1'000'000, max_index = 1'000'000;
    if (length > 1024 || length % 2 != 0) return -1;
    const std::size_t operation_count = length / 2;
    std::array<std::int64_t, capacity> node_value{};
    std::array<std::size_t, capacity + 1> next_node{};
    for (std::size_t i = 0; i < capacity; ++i) next_node[i] = i + 1;
    next_node[sentinel] = sentinel;
    std::size_t free_head = 0, tail = sentinel, count = 0;
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
            if (opcode == 0) {
                next_node[node] = sentinel;
                next_node[tail] = node;
                tail = node;
            } else {
                next_node[node] = next_node[sentinel];
                next_node[sentinel] = node;
                if (count == 0) tail = node;
            }
            ++count;
            returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            auto previous = sentinel;
            if (opcode == 3) while (next_node[previous] != tail) previous = next_node[previous];
            const auto node = next_node[previous];
            observed = node_value[node];
            next_node[previous] = next_node[node];
            if (node == tail) tail = previous;
            next_node[node] = free_head;
            free_head = node;
            --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -offset || payload > offset) return -1;
            auto previous = sentinel;
            while (next_node[previous] != sentinel && node_value[next_node[previous]] != payload)
                previous = next_node[previous];
            const auto node = next_node[previous];
            observed = node != sentinel;
            if (opcode == 4 && node != sentinel) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = static_cast<std::int64_t>(count);
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > max_index || count == 0 || static_cast<std::uint64_t>(payload) >= count) return -1;
            auto previous = sentinel;
            for (std::size_t index = 0; index < static_cast<std::size_t>(payload); ++index) previous = next_node[previous];
            const auto node = next_node[previous];
            observed = node_value[node];
            if (opcode == 8) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else return -1;
        if (returns_value) checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + offset);
    }

    auto node = next_node[sentinel];
    std::size_t index = 0;
    while (node != sentinel) {
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (node_value[node] + offset);
        node = next_node[node];
        ++index;
    }
    return checksum;
}
