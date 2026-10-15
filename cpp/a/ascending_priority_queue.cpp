/* Bounded linked-node pool for an ascending priority queue. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Node { std::int64_t value = 0; int next = -1; };
constexpr std::size_t max_operations = 512;
constexpr int max_capacity = 64;
}

extern "C" std::int64_t ascending_priority_queue(const std::int64_t *input,
                                                   std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > max_operations
        || length != 1 + 2 * static_cast<std::size_t>(input[0])) return -1;

    std::array<Node, max_capacity> nodes{};
    for (int index = 0; index < max_capacity - 1; ++index) nodes[index].next = index + 1;
    nodes[max_capacity - 1].next = -1;
    int free_head = 0, front = -1, rear = -1;
    std::int64_t checksum = 0;

    for (std::size_t operation = 0; operation < static_cast<std::size_t>(input[0]); ++operation) {
        const auto opcode = input[1 + 2 * operation];
        const auto payload = input[2 + 2 * operation];
        if (opcode == 0) {
            if (payload < -1'000'000 || payload > 1'000'000 || free_head < 0) return -1;
            const int node = free_head;
            free_head = nodes[node].next;
            nodes[node].value = payload;
            nodes[node].next = -1;
            if (front < 0) front = rear = node;
            else { nodes[rear].next = node; rear = node; }
        } else if (opcode == 1) {
            if (payload != 0 || front < 0) return -1;
            int previous = -1, current = front;
            int minimum = front, minimum_previous = -1;
            while (current >= 0) {
                if (nodes[current].value < nodes[minimum].value) {
                    minimum = current;
                    minimum_previous = previous;
                }
                previous = current;
                current = nodes[current].next;
            }
            checksum += static_cast<std::int64_t>(operation + 1) * (nodes[minimum].value + 1'000'001);
            if (minimum_previous < 0) front = nodes[minimum].next;
            else nodes[minimum_previous].next = nodes[minimum].next;
            if (rear == minimum) rear = minimum_previous;
            nodes[minimum].next = free_head;
            free_head = minimum;
        } else return -1;
    }

    std::size_t position = 1;
    for (int node = front; node >= 0; node = nodes[node].next, ++position)
        checksum += static_cast<std::int64_t>(position) * (nodes[node].value + 1'000'001);
    return checksum;
}
