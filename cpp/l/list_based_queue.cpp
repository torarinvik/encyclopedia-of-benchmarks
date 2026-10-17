#include <cstddef>
#include <cstdint>
#include <climits>

extern "C" std::int64_t list_based_queue(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;
    const std::size_t op_count = static_cast<std::size_t>(input[0]);
    std::int32_t node_values[32], next_node[32];
    std::int64_t words[64];
    std::size_t allocated = 0, word_count = 0, pos = 1, size = 0;
    std::int32_t head = -1, tail = -1;
    for (std::size_t i = 0; i < op_count; ++i) {
        if (pos >= length) return -1;
        const std::int64_t opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const std::int64_t value = input[pos++];
            if (value < INT32_MIN || value > INT32_MAX || allocated >= 32) return -1;
            const auto node = static_cast<std::int32_t>(allocated++);
            node_values[node] = static_cast<std::int32_t>(value);
            next_node[node] = -1;
            if (tail < 0) head = node;
            else next_node[tail] = node;
            tail = node;
            ++size;
            words[word_count++] = 0; words[word_count++] = 1;
        } else if (opcode == 1) {
            if (head < 0) return -1;
            const auto node = head;
            head = next_node[node];
            if (head < 0) tail = -1;
            --size;
            words[word_count++] = 1; words[word_count++] = node_values[node];
        } else if (opcode == 2) {
            if (head < 0) return -1;
            words[word_count++] = 2; words[word_count++] = node_values[head];
        } else if (opcode == 3) {
            head = tail = -1; size = 0;
            words[word_count++] = 3; words[word_count++] = 1;
        } else if (opcode == 4) {
            words[word_count++] = 4; words[word_count++] = size == 0 ? 1 : 0;
        } else if (opcode == 5) {
            words[word_count++] = 5; words[word_count++] = 0;
        } else return -1;
    }
    if (pos != length || length > 1 + 2 * op_count || word_count > 64) return -1;
    const std::size_t bytes = word_count * 8;
    if (output == nullptr || output_capacity < bytes) return -2;
    for (std::size_t i = 0; i < word_count; ++i) {
        const auto bits = static_cast<std::uint64_t>(words[i]);
        for (std::size_t b = 0; b < 8; ++b) output[8 * i + b] = static_cast<std::uint8_t>(bits >> (8 * b));
    }
    return static_cast<std::int64_t>(bytes);
}
