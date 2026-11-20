#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_q = 63;
constexpr std::size_t max_parseable_input = 128;
constexpr int value_offset = 100;
constexpr int value_count = 201;

void heap_push(std::array<int, max_q> &heap, int &size, int item) noexcept {
    int at = size++;
    while (at > 0) {
        const int parent = (at - 1) / 2;
        if (heap[static_cast<std::size_t>(parent)] <= item) break;
        heap[static_cast<std::size_t>(at)] = heap[static_cast<std::size_t>(parent)];
        at = parent;
    }
    heap[static_cast<std::size_t>(at)] = item;
}

int heap_pop(std::array<int, max_q> &heap, int &size) noexcept {
    const int result = heap[0];
    const int last = heap[static_cast<std::size_t>(--size)];
    if (size == 0) return result;
    int at = 0;
    for (;;) {
        int child = 2 * at + 1;
        if (child >= size) break;
        if (child + 1 < size && heap[static_cast<std::size_t>(child + 1)] < heap[static_cast<std::size_t>(child)]) ++child;
        if (heap[static_cast<std::size_t>(child)] >= last) break;
        heap[static_cast<std::size_t>(at)] = heap[static_cast<std::size_t>(child)];
        at = child;
    }
    heap[static_cast<std::size_t>(at)] = last;
    return result;
}

void normalize(std::array<int, max_q> &live, int &live_size,
               std::array<int, max_q> &deleted, int &deleted_size) noexcept {
    while (live_size > 0 && deleted_size > 0 && live[0] == deleted[0]) {
        heap_pop(live, live_size);
        heap_pop(deleted, deleted_size);
    }
}
}

extern "C" std::int64_t erasable_priority_queue_trace(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_input) return -1;
    if (input[0] < 0 || input[0] > max_q || length != 1 + 2 * static_cast<std::size_t>(input[0])) return -1;
    const int q = static_cast<int>(input[0]);
    std::array<int, value_count> count{};
    std::array<int, max_q> live{}, deleted{};
    int live_size = 0, deleted_size = 0;
    std::int64_t score = 0;

    for (int operation = 0; operation < q; ++operation) {
        const std::size_t input_at = 1 + 2 * static_cast<std::size_t>(operation);
        const std::int64_t opcode_raw = input[input_at];
        const std::int64_t operand_raw = input[input_at + 1];
        if (opcode_raw < 0 || opcode_raw > 3 || operand_raw < -100 || operand_raw > 100) return -1;
        const int opcode = static_cast<int>(opcode_raw);
        const int operand = static_cast<int>(operand_raw);
        int response = 0;
        normalize(live, live_size, deleted, deleted_size);

        if (opcode == 0) {
            heap_push(live, live_size, operand);
            ++count[static_cast<std::size_t>(operand + value_offset)];
            normalize(live, live_size, deleted, deleted_size);
        } else if (opcode == 1) {
            const std::size_t key = static_cast<std::size_t>(operand + value_offset);
            if (count[key] == 0) return -1;
            --count[key];
            heap_push(deleted, deleted_size, operand);
            response = 1;
            normalize(live, live_size, deleted, deleted_size);
        } else if (opcode == 2) {
            if (operand != 0) return -1;
            response = live_size == 0 ? -101 : live[0];
        } else {
            if (operand != 0 || live_size == 0) return -1;
            const int removed = heap_pop(live, live_size);
            --count[static_cast<std::size_t>(removed + value_offset)];
            response = removed;
        }
        const int token = opcode * 202 + response + 101;
        score += static_cast<std::int64_t>(operation + 1) * token;
    }
    return score;
}
