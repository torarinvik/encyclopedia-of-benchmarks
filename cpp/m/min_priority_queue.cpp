#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_capacity = 64;
constexpr std::size_t max_ops = 64;
constexpr std::size_t max_input_length = 130;
constexpr std::size_t max_output_words = 1 + 2 * max_ops;
constexpr std::size_t max_output_bytes = 4 * max_output_words;

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t min_priority_queue(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_capacity) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_ops)) return -1;

    const auto capacity = static_cast<std::size_t>(input[0]);
    const auto operation_count = static_cast<std::size_t>(input[1]);
    std::int32_t heap[max_capacity] = {};
    std::int32_t words[max_output_words];
    std::size_t heap_size = 0, word_count = 1, query_count = 0, pos = 2;

    for (std::size_t op = 0; op < operation_count; ++op) {
        if (pos >= length) return -1;
        const auto opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const auto raw = input[pos++];
            if (raw < INT32_MIN || raw > INT32_MAX || heap_size >= capacity) return -1;
            std::size_t index = heap_size;
            heap[index] = static_cast<std::int32_t>(raw);
            while (index > 0) {
                const auto parent = (index - 1) / 2;
                if (heap[parent] <= heap[index]) break;
                const auto tmp = heap[parent];
                heap[parent] = heap[index];
                heap[index] = tmp;
                index = parent;
            }
            ++heap_size;
        } else if (opcode == 1 || opcode == 2) {
            if (heap_size == 0) return -1;
            const auto value = heap[0];
            if (opcode == 2) {
                --heap_size;
                if (heap_size > 0) {
                    heap[0] = heap[heap_size];
                    std::size_t index = 0;
                    for (;;) {
                        const auto left = 2 * index + 1;
                        if (left >= heap_size) break;
                        const auto right = left + 1;
                        auto child = left;
                        if (right < heap_size && heap[right] < heap[left]) child = right;
                        if (heap[index] <= heap[child]) break;
                        const auto tmp = heap[index];
                        heap[index] = heap[child];
                        heap[child] = tmp;
                        index = child;
                    }
                }
            }
            words[word_count++] = (opcode == 1) ? 1 : 2;
            words[word_count++] = value;
            ++query_count;
        } else if (opcode == 3 || opcode == 4) {
            words[word_count++] = (opcode == 3) ? 3 : 4;
            words[word_count++] = (opcode == 3) ? (heap_size == 0) : (heap_size == capacity);
            ++query_count;
        } else return -1;
    }

    if (pos != length || word_count > max_output_words) return -1;
    words[0] = static_cast<std::int32_t>(query_count);
    const auto bytes = word_count * 4;
    if (bytes > max_output_bytes || output == nullptr || output_capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    for (std::size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
