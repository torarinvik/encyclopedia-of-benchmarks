#include <cstddef>
#include <cstdint>

namespace {
void store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t element_priority_queue_using_list(const std::int64_t* input, std::size_t length,
                                                            std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 514) return -1;
    const auto op_count = input[0];
    if (op_count < 0 || op_count > 256 || length != 1 + 2 * static_cast<std::size_t>(op_count)) return -1;
    std::int32_t queue[100]{};
    std::size_t queue_count = 0;
    std::int64_t dequeued[128]{};
    std::size_t dequeued_count = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(op_count); ++i) {
        const auto opcode = input[1 + 2 * i], argument = input[2 + 2 * i];
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || queue_count == 100) return -1;
            queue[queue_count++] = static_cast<std::int32_t>(argument);
        } else if (opcode == 1) {
            if (argument != 0 || queue_count == 0) return -1;
            std::size_t minimum = 0;
            for (std::size_t j = 1; j < queue_count; ++j) if (queue[j] < queue[minimum]) minimum = j;
            dequeued[dequeued_count++] = queue[minimum];
            --queue_count;
            for (std::size_t j = minimum; j < queue_count; ++j) queue[j] = queue[j + 1];
        } else return -1;
    }
    const std::size_t output_bytes = dequeued_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < dequeued_count; ++i) store_i64(output, i * 8, dequeued[i]);
    return static_cast<std::int64_t>(output_bytes);
}
