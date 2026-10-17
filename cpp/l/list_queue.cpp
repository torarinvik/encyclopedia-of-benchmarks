#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_queue_size = 10;
constexpr std::size_t max_ops = 64;
constexpr std::size_t max_input_length = 129;
constexpr std::size_t max_output_words = 130;
constexpr std::size_t max_output_bytes = 4 * max_output_words;

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t list_queue(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_ops)) return -1;
    const auto op_count = static_cast<std::size_t>(input[0]);
    std::int32_t queue[max_queue_size] = {};
    std::int32_t words[max_output_words];
    std::size_t word_count = 1, query_count = 0, pos = 1, queue_size = 0;
    for (std::size_t op = 0; op < op_count; ++op) {
        if (pos >= length) return -1;
        const auto opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const auto raw = input[pos++];
            if (raw < INT32_MIN || raw > INT32_MAX || queue_size >= max_queue_size) return -1;
            queue[queue_size++] = static_cast<std::int32_t>(raw);
        } else if (opcode == 1) {
            if (queue_size == 0) {
                words[word_count++] = 3;
                words[word_count++] = 0;
            } else {
                const auto value = queue[0];
                for (std::size_t i = 0; i + 1 < max_queue_size; ++i) queue[i] = queue[i + 1];
                --queue_size;
                words[word_count++] = 1;
                words[word_count++] = value;
            }
            ++query_count;
        } else if (opcode == 2) {
            words[word_count++] = 2;
            words[word_count++] = static_cast<std::int32_t>(queue_size);
            ++query_count;
        } else return -1;
    }
    if (pos != length || word_count + 1 + queue_size > max_output_words) return -1;
    words[0] = static_cast<std::int32_t>(query_count);
    words[word_count++] = static_cast<std::int32_t>(queue_size);
    for (std::size_t i = 0; i < queue_size; ++i) words[word_count++] = queue[i];
    const auto bytes = word_count * 4;
    if (bytes > max_output_bytes || output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    for (std::size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
