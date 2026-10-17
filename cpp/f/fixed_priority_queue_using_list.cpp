#include <cstddef>
#include <cstdint>

namespace {
void store_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t fixed_priority_queue_using_list(const std::int64_t* input, std::size_t length,
                                                          std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 770) return -1;
    const auto op_count = input[0];
    if (op_count < 0 || op_count > 256 || length != 1 + 3 * static_cast<std::size_t>(op_count)) return -1;
    std::int32_t buckets[3][100]{};
    std::size_t counts[3]{};
    std::int64_t dequeued[128]{};
    std::size_t dequeued_count = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(op_count); ++i) {
        const auto opcode = input[1 + 3 * i], priority = input[2 + 3 * i], data = input[3 + 3 * i];
        if (opcode == 0) {
            if (priority < -3 || priority > 2 || data < INT32_MIN || data > INT32_MAX) return -1;
            const auto bucket = static_cast<std::size_t>(priority < 0 ? priority + 3 : priority);
            if (counts[bucket] == 100) return -1;
            buckets[bucket][counts[bucket]++] = static_cast<std::int32_t>(data);
        } else if (opcode == 1) {
            if (priority != 0 || data != 0) return -1;
            std::size_t bucket = 0;
            while (bucket < 3 && counts[bucket] == 0) ++bucket;
            if (bucket == 3) return -1;
            dequeued[dequeued_count++] = buckets[bucket][0];
            --counts[bucket];
            for (std::size_t j = 0; j < counts[bucket]; ++j) buckets[bucket][j] = buckets[bucket][j + 1];
        } else return -1;
    }
    const std::size_t output_bytes = dequeued_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < dequeued_count; ++i) store_i64(output, i * 8, dequeued[i]);
    return static_cast<std::int64_t>(output_bytes);
}
